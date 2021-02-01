module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.env_name
  cluster_version = var.eks_version

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.private_subnets

  tags = {
    Environment = var.env_name
  }

  workers_group_defaults = {
  	root_volume_type = "gp2"
  }

  worker_groups = [
    {
      name                          = "worker-group"
      instance_type                 = var.node_machine_type
      asg_desired_capacity          = var.node_count
      asg_max_size                  = var.node_count
      asg_min_size                  = var.node_count
    },
  ]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
