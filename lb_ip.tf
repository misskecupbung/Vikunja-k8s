# Global static IP for the GCE Ingress load balancer.
# If you already manually created an address with the same name, Terraform will import it on first apply (must match name & project).
resource "google_compute_global_address" "platform_lb" {
  name         = var.global_lb_ip_name
  project      = var.project_id
  address_type = "EXTERNAL"
  # Let GCP allocate the address. To force a specific one, add `address = "<existing ip>"`.
  # purpose/reservation_type not needed for standard IPv4 LB address.
  lifecycle {
    prevent_destroy = false
  }
}
