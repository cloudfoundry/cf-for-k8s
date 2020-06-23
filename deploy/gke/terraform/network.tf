resource "google_compute_network" "primary" {
  name = "${var.env_name}-vpc"
}
