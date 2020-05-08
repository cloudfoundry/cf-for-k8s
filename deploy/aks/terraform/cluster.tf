resource "azurerm_kubernetes_cluster" "primary" {
  name                = var.env_name
  location            = var.location
  resource_group_name = azurerm_resource_group.primary.name
  dns_prefix          = var.env_name

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.node_vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "kubenet"
    network_policy = "calico"
  }
}
