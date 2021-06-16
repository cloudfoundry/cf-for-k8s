terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.62.1"
    }
    google = {
      source = "hashicorp/google"
    }
  }
  required_version = ">= 0.13"
}
