variable "service_principal_id" {
  type = string
}

variable "service_principal_secret" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "google_project" {
  type = string
}

variable "google_region" {
  type = string
}

variable "google_service_account_key" {
  type = string
}

variable "location" {
  type = string
  default = "West US"
}

variable "env_name" {
  type = string
}

variable "env_dns_domain" {
  type = string
}

variable "dns_zone_name" {
  type = string
}

variable "node_count" {
  type = number
  default = 5
}

variable "node_vm_size" {
  type = string
  default = "Standard_DS3_v2"
}
