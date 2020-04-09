resource "google_compute_address" "lb_static_ip" {
  name = "${var.env_name}-lb"
  project = var.project
  region = var.region
}
