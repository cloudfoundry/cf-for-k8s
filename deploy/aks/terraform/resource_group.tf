resource "azurerm_resource_group" "primary" {
  name     = var.env_name
  location = var.location
}
