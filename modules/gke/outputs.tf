output "cluster_name" {
  value       = google_container_cluster.this.name
  description = "GKE cluster name"
}

output "endpoint" {
  value       = google_container_cluster.this.endpoint
  description = "GKE API endpoint"
}

output "ca_certificate" {
  value       = google_container_cluster.this.master_auth[0].cluster_ca_certificate
  description = "Cluster CA cert"
}
