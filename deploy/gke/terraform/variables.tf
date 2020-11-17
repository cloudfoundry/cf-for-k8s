variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "service_account_key" {
  type = string
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

variable "network_name" {
  type = string
  default = "default"
}

variable "subnet_name" {
  type = string
  default = "default"
}

variable "node_count" {
  type = number
  default = 5
}

variable "node_machine_type" {
  type = string
  default = "n1-standard-4"
}

variable "release_channel" {
  type = string
  default = "RAPID"
}
