variable "project_id" {
  type        = string
  description = "GCP project id where infrastructure is provisioned"
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "Primary region for regional resources (aligned with CI workflow)"
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


variable "vikunja_db_password" {
  type        = string
  sensitive   = true
  description = "Password for the primary Vikunja application database user (supply via TF_VAR_vikunja_db_password)."
}

variable "vikunja_db_name" {
  type        = string
  default     = "vikunja"
  description = "Primary Vikunja database name within the Cloud SQL instance"
}

variable "vikunja_db_user" {
  type        = string
  default     = "vikunja"
  description = "Primary Vikunja database user"
}

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

variable "cluster_location" {
  type        = string
  default     = null
  description = "Optional zonal location to create a zonal GKE cluster instead of regional (e.g. us-central1-a). When null, use regional cluster."
}

variable "gke_disk_size_gb" {
  type        = number
  default     = 30
  description = "GKE node boot disk size in GB (keep small in dev to reduce SSD quota)."
}

variable "authorized_networks" {
  type = list(object({
    name  = string
    value = string
  }))
  default     = []
  description = "Authorized public CIDR networks for Cloud SQL (passed through to module). Keep empty or narrow; avoid 0.0.0.0/0 in prod."
}

variable "keycloak_db_name" {
  type        = string
  default     = "keycloak" # corrected spelling
  description = "Dedicated Keycloak database name on the shared Cloud SQL instance"
}

variable "keycloak_db_user" {
  type        = string
  default     = "keycloak"
  description = "Dedicated Keycloak database user name"
}

variable "keycloak_db_password" {
  type        = string
  sensitive   = true
  default     = null
  description = "Password for the Keycloak DB user (supply via TF_VAR_keycloak_db_password). If null, Terraform will not attempt to manage the user password (manual)."
}

variable "platform_lb_ip_name" {
  type        = string
  default     = "vikunja-platform-lb-ip"
  description = "Name of the global static IPv4 address reserved for the GCE Ingress load balancer."
}

variable "enable_private_nodes" {
  type        = bool
  default     = false
  description = "Enable private GKE nodes (no external IPs). Requires Cloud NAT for outbound internet pulls."
}

variable "enable_private_endpoint" {
  type        = bool
  default     = false
  description = "Restrict GKE control plane to private endpoint only (set true only if you have VPN/Interconnect or Connect Gateway)."
}

variable "master_ipv4_cidr_block" {
  type        = string
  default     = "172.16.0.0/28"
  description = "RFC1918 /28 for master endpoint in private clusters. Must not overlap existing ranges."
}

variable "enable_cloud_nat" {
  type        = bool
  default     = false
  description = "Provision Cloud NAT for outbound internet when using private nodes."
}

variable "nat_allocate_option" {
  type        = string
  default     = "AUTO_ONLY"
  description = "Cloud NAT IP allocation option (AUTO_ONLY or MANUAL_ONLY)."
}