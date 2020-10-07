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

variable "machine_type" {
  type = string
  default = "n2-standard-16"
}
