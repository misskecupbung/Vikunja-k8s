variable "project_id" {
  type        = string
  description = "GCP project id"
}

variable "region" {
  type        = string
  description = "Primary region for resources"
}

variable "network_name" {
  type        = string
  default     = "vikunja-vpc"
  description = "Name of the VPC network"
}

variable "network_cidr" {
  type        = string
  description = "Primary CIDR for the subnet"
}

variable "subnet_name" {
  type        = string
  default     = "vikunja-subnet"
  description = "Name of the primary regional subnet"
}

variable "subnet_cidr" {
  type        = string
  description = "Subnet CIDR"
}

variable "pods_secondary_range" {
  type        = string
  description = "Secondary range for pods"
}

variable "services_secondary_range" {
  type        = string
  description = "Secondary range for services"
}
