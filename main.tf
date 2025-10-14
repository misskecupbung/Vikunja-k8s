module "network" {
  source                   = "./modules/network"
  project_id               = var.project_id
  region                   = var.region
  network_cidr             = var.network_cidr
  subnet_cidr              = var.subnet_cidr
  pods_secondary_range     = var.pods_cidr
  services_secondary_range = var.services_cidr
}

module "gke" {
  source                          = "./modules/gke"
  project_id                      = var.project_id
  region                          = var.region
  cluster_name                    = var.cluster_name
  subnet_name                     = module.network.subnet_name
  network_name                    = "vikunja-vpc"
  location                        = var.cluster_location
  pods_secondary_range_name       = "pods"
  services_secondary_range_name   = "services"
  release_channel                 = "REGULAR"
  min_nodes                       = var.gke_min_nodes
  max_nodes                       = var.gke_max_nodes
  machine_type                    = var.gke_machine_type
  disk_size_gb                    = var.gke_disk_size_gb
  enable_workload_identity        = true
  enable_vertical_pod_autoscaling = false
  labels                          = { env = "dev" }
}

module "cloudsql" {
  source               = "./modules/cloudsql"
  count                = var.enable_cloudsql ? 1 : 0
  project_id           = var.project_id
  region               = var.region
  instance_name        = "vikunja-db"
  db_tier              = var.cloudsql_tier
  database_name        = var.vikunja_db_name
  db_user              = var.vikunja_db_user
  db_password          = var.vikunja_db_password
  availability_type    = var.cloudsql_availability_type
  deletion_protection  = false
  authorized_networks  = var.authorized_networks
  keycloak_db_name     = var.keycloak_db_name
  keycloak_db_user     = var.keycloak_db_user
  keycloak_db_password = var.keycloak_db_password
}