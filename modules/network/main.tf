terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

resource "google_compute_network" "this" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
  description             = "VPC for Vikunja GKE cluster"
}

resource "google_compute_subnetwork" "this" {
  name                     = var.subnet_name
  project                  = var.project_id
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.this.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_secondary_range
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_secondary_range
  }
}

# Reserve an internal IP range for private service networking (Cloud SQL private IP)
resource "google_compute_global_address" "private_service_range" {
  name          = "cloudsql-private-range"
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.this.id
}

# Establish private VPC peering connection for Google managed services (Cloud SQL)
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.this.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_range.name]
}

# Optional Cloud NAT for private nodes outbound internet access
resource "google_compute_router" "nat_router" {
  count   = var.enable_cloud_nat ? 1 : 0
  name    = "${var.network_name}-nat-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.this.id
}

resource "google_compute_router_nat" "nat" {
  count                              = var.enable_cloud_nat ? 1 : 0
  name                               = "${var.network_name}-nat"
  project                            = var.project_id
  region                             = var.region
  router                             = google_compute_router.nat_router[0].name
  nat_ip_allocate_option             = var.nat_allocate_option
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  enable_endpoint_independent_mapping = true
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}