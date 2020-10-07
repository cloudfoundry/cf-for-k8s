provider "google" {
  project     = var.project
  region      = var.region
  credentials = var.service_account_key
}
