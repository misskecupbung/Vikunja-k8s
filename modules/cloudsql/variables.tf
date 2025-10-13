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

variable "enable_public_ip" {
  type        = bool
  default     = true
  description = "Enable a public IPv4 address for the instance (dev convenience). Disable and use private_network in prod."
}

variable "private_network" {
  type        = string
  default     = null
  description = "Self-link of the VPC network for private IP (when enable_public_ip=false)."
}

variable "authorized_networks" {
  type = list(object({
    name  = string
    value = string
  }))
  default     = []
  description = "List of authorized public CIDR networks to allow (public IPv4). Use narrow ranges; avoid 0.0.0.0/0 in production."
}

# Optional secondary (Keycloak) database & user
variable "keycloak_db_name" {
  type        = string
  default     = null
  description = "If set, create a dedicated Keycloak database on the same instance"
}

variable "keycloak_db_user" {
  type        = string
  default     = null
  description = "If set with keycloak_db_name, create a Keycloak DB user"
}

variable "keycloak_db_password" {
  type        = string
  default     = null
  sensitive   = true
  description = "Password for the Keycloak DB user (if managing via Terraform)"
}
