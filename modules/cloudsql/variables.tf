variable "project_id" {
  type        = string
  description = "GCP project id"
}

variable "region" {
  type        = string
  description = "Region where the Cloud SQL instance is deployed"
}

variable "instance_name" {
  type        = string
  default     = "vikunja-db"
  description = "Cloud SQL instance name"
}

variable "db_tier" {
  type        = string
  default     = "db-custom-1-3840"
  description = "Machine tier for Cloud SQL (custom vCPU/memory)"
}

variable "database_name" {
  type        = string
  default     = "vikunja"
  description = "Primary application database name"
}

variable "db_user" {
  type        = string
  default     = "vikunja"
  description = "Database user name"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "Password for the database user (consider Secret Manager in prod)"
}

variable "availability_type" {
  type        = string
  default     = "REGIONAL"
  description = "'ZONAL' or 'REGIONAL' for HA posture"
}

variable "deletion_protection" {
  type        = bool
  default     = false
  description = "Enable to prevent accidental instance deletion"
}
