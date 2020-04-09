variable "project" {
  type = string
}

variable "region" {
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

variable "release_channel" {
  type = string
  default = "RAPID"
}
