module "eks" {
  source  = "terraform-aws-modules/eks/aws"

  cluster_name    = var.env_name
  cluster_version = var.eks_version

  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  self_managed_node_groups = {
    worker_group = {
      name          = "worker-group"
      instance_type = var.node_machine_type
      desired_size  = var.node_count
      max_size      = var.node_count
      min_size      = var.node_count
    }
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
