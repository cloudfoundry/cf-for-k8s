module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.21.0"

  cluster_name    = var.env_name
  cluster_version = var.eks_version

  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  eks_managed_node_groups = {
    worker-group = {
      instance_types = [var.node_machine_type]
      capacity_type  = "SPOT"
      min_size       = var.node_count
      max_size       = var.node_count
      desired_size   = var.node_count
    },
  }

  tags = {
    Environment = var.env_name
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
