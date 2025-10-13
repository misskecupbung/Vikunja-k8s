project_id      = "sixth-bonbon-475003-q2"
region          = "us-central1"
enable_cloudsql = true

# GKE sizing (dev)
gke_min_nodes    = 2
gke_max_nodes    = 4
gke_machine_type = "n1-standard-2"
cluster_location = "us-central1-a"
gke_disk_size_gb = 20

# Cloud SQL sizing (dev)
cloudsql_tier              = "db-f1-micro"
cloudsql_availability_type = "ZONAL"

# WARNING: 0.0.0.0/0 exposes the instance publicly. Use only for temporary dev troubleshooting.
# Replace with a narrow /32 (your NAT or workstation public IP) ASAP.
authorized_networks = [
  {
    name  = "any"
    value = "0.0.0.0/0"
  }
]
