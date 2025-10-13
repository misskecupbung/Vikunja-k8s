terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "network" {
  source                = "./modules/network"
  project_id            = var.project_id
  region                = var.region
  network_cidr          = var.network_cidr
  subnet_cidr           = var.subnet_cidr
  pods_secondary_range  = var.pods_cidr
  services_secondary_range = var.services_cidr
}

module "gke" {
  source                          = "./modules/gke"
  project_id                      = var.project_id
  region                          = var.region
  cluster_name                    = var.cluster_name
  subnet_name                     = module.network.subnet_name
  network_name                    = var.network_cidr != "" ? "vikunja-vpc" : "vikunja-vpc"
  pods_secondary_range_name       = "pods"
  services_secondary_range_name   = "services"
  release_channel                 = "REGULAR"
  min_nodes                       = 1
  max_nodes                       = 3
  machine_type                    = "e2-standard-4"
  enable_workload_identity        = true
  enable_vertical_pod_autoscaling = true
  labels                          = { env = "dev" }
}

module "cloudsql" {
  source              = "./modules/cloudsql"
  count               = var.enable_cloudsql ? 1 : 0
  project_id          = var.project_id
  region              = var.region
  instance_name       = "vikunja-db"
  db_tier             = "db-custom-1-3840"
  database_name       = "vikunja"
  db_user             = "vikunja"
  db_password         = var.db_password
  availability_type   = "REGIONAL"
  deletion_protection = false
}

// outputs moved to outputs.tf
