variable "project_id" {
  type        = string
  description = "GCP project id"
}

variable "region" {
  type        = string
  description = "Region (or zone for zonal clusters) where GKE is deployed"
}

variable "cluster_name" {
  type        = string
  description = "Name of the GKE cluster"
}

variable "subnet_name" {
  type        = string
  description = "Existing subnet name for cluster primary network interface"
}

variable "network_name" {
  type        = string
  description = "VPC network name"
}

variable "release_channel" {
  type        = string
  default     = "REGULAR"
  description = "GKE release channel (RAPID | REGULAR | STABLE)"
}

variable "min_nodes" {
  type        = number
  default     = 1
  description = "Minimum nodes in the primary node pool"
}

variable "max_nodes" {
  type        = number
  default     = 3
  description = "Maximum nodes in the primary node pool"
}

variable "machine_type" {
  type        = string
  default     = "e2-standard-4"
  description = "Machine type for node pool"
}

variable "pods_secondary_range_name" {
  type        = string
  default     = "pods"
  description = "Secondary range name in subnet for Pod IPs"
}

variable "services_secondary_range_name" {
  type        = string
  default     = "services"
  description = "Secondary range name in subnet for Service IPs"
}

variable "enable_workload_identity" {
  type        = bool
  default     = true
  description = "Enable GKE Workload Identity for pod-to-GCP IAM"
}

variable "enable_vertical_pod_autoscaling" {
  type        = bool
  default     = true
  description = "Enable cluster-level Vertical Pod Autoscaler"
}

variable "enable_private_nodes" {
  type        = bool
  default     = false
  description = "Create cluster with private nodes (no public IPs on VMs)"
}

variable "enable_private_endpoint" {
  type        = bool
  default     = false
  description = "If true, restrict master/API server to private endpoint only (requires internal access)"
}

variable "master_ipv4_cidr_block" {
  type        = string
  default     = null
  description = "RFC1918 /28 block for master endpoints when private cluster config is enabled (e.g. 172.16.0.0/28)"
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Additional resource labels applied to nodes"
}

variable "disk_size_gb" {
  type        = number
  default     = 100
  description = "Node boot disk size in GB"
}

variable "location" {
  type        = string
  default     = null
  description = "Override location (zone) for a zonal cluster instead of regional. When null, region is used for a regional cluster."
}
