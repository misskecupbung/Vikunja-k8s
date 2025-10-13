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
  name                  = var.subnet_name
  project               = var.project_id
  ip_cidr_range         = var.subnet_cidr
  region                = var.region
  network               = google_compute_network.this.id
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