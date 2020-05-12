output "vm_name" {
  value = google_compute_instance.default.name
}

output "vm_ssh_private_key" {
  value = tls_private_key.default.private_key_pem
  sensitive = true
}

output "vm_ssh_public_key" {
  value = tls_private_key.default.public_key_openssh
}
