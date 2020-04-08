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

variable "release_channel" {
  type = string
  value = "RAPID"
}
