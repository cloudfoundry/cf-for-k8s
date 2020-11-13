module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.6.0"

  name                 = "${var.env_name}-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = var.azs
  private_subnets      = var.private_subnets
  public_subnets       = var.public_subnets
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${var.env_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.env_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.env_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}
