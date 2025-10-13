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
  source                        = "./modules/gke"
  project_id                    = var.project_id
  region                        = var.region
  cluster_name                  = var.cluster_name
  subnet_name                   = module.network.subnet_name
  network_name                  = var.network_cidr != "" ? "vikunja-vpc" : "vikunja-vpc"
  pods_secondary_range_name     = "pods"
  services_secondary_range_name = "services"
  # Reduced footprint for quota: change via tfvars for prod
  release_channel                 = "REGULAR"
  min_nodes                       = var.gke_min_nodes
  max_nodes                       = var.gke_max_nodes
  machine_type                    = var.gke_machine_type
  enable_workload_identity        = true
  enable_vertical_pod_autoscaling = false # disable to save overhead in dev
  labels                          = { env = "dev" }
}

module "cloudsql" {
  source        = "./modules/cloudsql"
  count         = var.enable_cloudsql ? 1 : 0
  project_id    = var.project_id
  region        = var.region
  instance_name = "vikunja-db"
  # Smaller tier for development to fit quota (1 vCPU, 1.7GB approx)
  db_tier             = var.cloudsql_tier
  database_name       = "vikunja"
  db_user             = "vikunja"
  db_password         = var.db_password
  availability_type   = var.cloudsql_availability_type
  deletion_protection = false
}