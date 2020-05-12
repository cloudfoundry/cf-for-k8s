output "lb_static_ip" {
  value = azurerm_public_ip.lb_static_ip.ip_address
}

output "kubeconfig" {
  value = azurerm_kubernetes_cluster.primary.kube_config_raw
  sensitive = true
}
