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

variable "labels" {
  type        = map(string)
  default     = {}
  description = "Additional resource labels applied to nodes"
}
