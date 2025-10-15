output "network" {
  value       = google_compute_network.this.self_link
  description = "Self link of the VPC network"
}

output "subnet" {
  value       = google_compute_subnetwork.this.self_link
  description = "Self link of the subnet"
}

output "subnet_name" {
  value       = google_compute_subnetwork.this.name
  description = "Name of the primary subnet"
}

output "cloud_nat_enabled" {
  value       = length(google_compute_router_nat.nat) > 0
  description = "Whether Cloud NAT was created"
}
