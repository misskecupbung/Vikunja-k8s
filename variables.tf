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
	default     = "ChangeMe123!"
	sensitive   = true
	description = "Database password (demo default, replace via tfvars or secret)"
}
