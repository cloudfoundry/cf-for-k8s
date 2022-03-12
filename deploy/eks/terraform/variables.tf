variable "access_key_id" {
  description = "AWS access key ID"
  type = string
}

variable "secret_access_key" {
  description = "AWS secret access key"
  type = string
}

variable "region" {
  description = "AWS region"
  type = string
  default     = "us-west-2"
}

variable "azs" {
  description = "Availability zones for the configured region"
  default = ["us-west-2a","us-west-2b","us-west-2c","us-west-2d"]
}

variable "private_subnets" {
  description = "A list of private subnets, one per configured availability zone"
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
}

variable "public_subnets" {
  description = "A list of public subnets, one per configured availability zone"
  default = ["10.0.5.0/24", "10.0.6.0/24", "10.0.7.0/24", "10.0.8.0/24"]
}

variable "env_name" {
  description = "The environment name is used as a prefix to uniquely identify resources in the project"
  type = string
}

variable "node_count" {
  description = "Number of desired Kubernetes nodes"
  type = number
  default = 5
}

variable "node_machine_type" {
  description = "Kubernetes node machine type"
  type = string
  default = "t3.xlarge"
}

variable "eks_version" {
  description = "Kubernetes cluster version"
  type = string
  default = "1.21"
}
