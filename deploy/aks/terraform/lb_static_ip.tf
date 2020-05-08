resource "azurerm_public_ip" "lb_static_ip" {
  name                = "${var.env_name}-lb"
  location            = var.location
  resource_group_name = azurerm_kubernetes_cluster.primary.node_resource_group // The LoadBalancer static IP has to exist in the same resource group as the LoadBalancer itself
  allocation_method   = "Static" // We want to know the IP address ahead of time so that we an set up DNS for it
  sku                 = "Standard" // The SKU for the LoadBalancer static IP has to match the LoadBalancer itself
}
