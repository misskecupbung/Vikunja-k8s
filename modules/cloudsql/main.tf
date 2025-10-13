terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

resource "google_sql_database_instance" "this" {
  name                = var.instance_name
  project             = var.project_id
  region              = var.region
  database_version    = "POSTGRES_15"
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.db_tier
    availability_type = var.availability_type
    disk_autoresize   = true
    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
    }
    maintenance_window {
      day  = 7
      hour = 3
    }
    ip_configuration {
      # For dev simplicity we enable public IPv4; set to false and supply private_network for production
      ipv4_enabled    = var.enable_public_ip
      private_network = var.private_network
    }
  }
}

resource "google_sql_database" "db" {
  name     = var.database_name
  instance = google_sql_database_instance.this.name
  project  = var.project_id
}

resource "google_sql_user" "user" {
  name     = var.db_user
  instance = google_sql_database_instance.this.name
  project  = var.project_id
  password = var.db_password
}