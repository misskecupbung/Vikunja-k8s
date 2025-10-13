variable "project_id" {
  type        = string
  description = "GCP project id where infrastructure is provisioned"
}

variable "region" {
  type        = string
  default     = "europe-west1"
  description = "Primary region for regional resources"
}

variable "network_cidr" {
  type        = string
  default     = "10.10.0.0/20"
  description = "(Optional/unused placeholder) overall network CIDR reference"
}

variable "subnet_cidr" {
  type        = string
  default     = "10.10.0.0/24"
  description = "Primary subnet CIDR block"
}

variable "pods_cidr" {
  type        = string
  default     = "10.10.32.0/19"
  description = "Secondary IP range for GKE Pods"
}

variable "services_cidr" {
  type        = string
  default     = "10.10.64.0/20"
  description = "Secondary IP range for GKE Services"
}

variable "cluster_name" {
  type        = string
  default     = "vikunja-gke"
  description = "Name of the GKE cluster"
}

variable "enable_cloudsql" {
  type        = bool
  default     = true
  description = "Toggle to provision managed Cloud SQL (otherwise use self-hosted Postgres)"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Database password (supply via TF_VAR_db_password env or secret manager; no default)"
}

# Sizing variables (override in per-environment tfvars)
variable "gke_min_nodes" {
  type        = number
  default     = 1
  description = "Minimum number of nodes in primary node pool"
}

variable "gke_max_nodes" {
  type        = number
  default     = 2
  description = "Maximum number of nodes in primary node pool"
}

variable "gke_machine_type" {
  type        = string
  default     = "e2-standard-2"
  description = "Machine type for GKE nodes (dev default smaller)"
}

variable "cloudsql_tier" {
  type        = string
  default     = "db-f1-micro"
  description = "Cloud SQL tier (db-f1-micro for dev; override to production tier in prod tfvars)"
}

variable "cloudsql_availability_type" {
  type        = string
  default     = "ZONAL"
  description = "Cloud SQL availability type (ZONAL for dev, REGIONAL for HA prod)"
}
