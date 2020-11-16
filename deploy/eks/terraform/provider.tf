provider "aws" {
  version = ">= 2.28.1"
  region  = "us-west-2"
  access_key = var.access_key_id
  secret_key = var.secret_access_key
}

provider "kubernetes" {
  load_config_file       = "false"
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}
