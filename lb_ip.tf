resource "google_compute_global_address" "platform_lb" {
  name         = var.platform_lb_ip_name
  project      = var.project_id
  address_type = "EXTERNAL"
  lifecycle {
    prevent_destroy = false
  }
}
