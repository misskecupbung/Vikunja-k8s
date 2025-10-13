project_id      = "sixth-bonbon-475003-q2"
region          = "us-central1"
enable_cloudsql = true

# GKE sizing (prod)
gke_min_nodes    = 2
gke_max_nodes    = 4
gke_machine_type = "e2-standard-4"

# Cloud SQL sizing (prod)
cloudsql_tier              = "db-custom-2-7680"
cloudsql_availability_type = "REGIONAL"
