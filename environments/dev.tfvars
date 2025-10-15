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
#enable_private_nodes       = true
#enable_private_endpoint    = false
#master_ipv4_cidr_block     = "172.16.0.0/28"
#enable_cloud_nat           = true
#nat_allocate_option        = "AUTO_ONLY"