provider "google-beta" {
  project     = var.project
  region      = var.region
  credentials = var.service_account_key
}
