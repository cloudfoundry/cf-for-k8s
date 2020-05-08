provider "azurerm" {
  client_id = var.service_principal_id
  client_secret = var.service_principal_secret
  subscription_id = var.subscription_id
  tenant_id = var.tenant_id

  features {}
}

// Used for DNS management
provider "google" {
  project     = var.google_project
  region      = var.google_region
  credentials = var.google_service_account_key
}
