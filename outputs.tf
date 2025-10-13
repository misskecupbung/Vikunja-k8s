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
