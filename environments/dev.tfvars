project_id      = "sixth-bonbon-475003-q2"
region          = "us-central1"
enable_cloudsql = true

# GKE sizing (dev)
gke_min_nodes    = 3
gke_max_nodes    = 4
gke_machine_type = "e2-medium"     # smaller shared-core for dev
cluster_location = "us-central1-a" # zonal to reduce regional resource usage
gke_disk_size_gb = 20

# Cloud SQL sizing (dev)
cloudsql_tier              = "db-f1-micro"
cloudsql_availability_type = "ZONAL"
