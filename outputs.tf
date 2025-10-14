output "network_name" {
  value       = "vikunja-vpc"
  description = "Name assigned to the VPC"
}

output "subnet_name" {
  value       = module.network.subnet_name
  description = "Primary subnet name"
}

output "gke_cluster_name" {
  value       = module.gke.cluster_name
  description = "Deployed GKE cluster name"
}

output "cloudsql_instance" {
  value       = try(module.cloudsql[0].instance_connection_name, null)
  description = "Cloud SQL instance connection name or null if disabled"
}

output "cloudsql_public_ip" {
  value       = try(module.cloudsql[0].public_ip_address, null)
  description = "Cloud SQL public IPv4 address (null if private or disabled)"
}

output "keycloak_db_name" {
  value       = try(module.cloudsql[0].keycloak_db_name, null)
  description = "Dedicated Keycloak database name (null if not managed)"
}

output "keycloak_db_user" {
  value       = try(module.cloudsql[0].keycloak_db_user, null)
  description = "Dedicated Keycloak database user (null if not managed)"
}

output "platform_lb_ip_name" {
  value       = var.global_lb_ip_name
  description = "Name of the global static IP reserved for the platform ingress"
}

output "platform_lb_ip_address" {
  value       = google_compute_global_address.platform_lb.address
  description = "Allocated global static IPv4 address for the platform ingress"
}
