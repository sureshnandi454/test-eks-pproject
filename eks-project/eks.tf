# Define provider
provider "aws" {
  region = "us-west-2"
}

# Create VPC using module
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "eks-vpc"
  cidr   = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Create EKS cluster using module
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  cluster_name = "eks-cluster"

  subnets = module.vpc.private_subnets

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Create managed node group using module
module "eks_nodes" {
  source = "terraform-aws-modules/eks/aws//modules/managed_node_group"
  cluster_name = module.eks.cluster_id
  node_group_name = "eks-node-group"
  instance_types = ["t2.micro"]
  min_size = 1
  desired_capacity = 1
  max_size = 1
  subnets = module.vpc.private_subnets
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Create Internet Gateway using module
module "internet_gateway" {
  source = "terraform-aws-modules/vpc/aws//modules/internet-gateway"
  vpc_id = module.vpc.vpc_id

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Create NAT Gateway using module
module "nat_gateway" {
  source = "terraform-aws-modules/vpc/aws//modules/nat-gateway"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Create Route Tables using module
module "route_tables" {
  source = "terraform-aws-modules/vpc/aws//modules/route-table"
  vpc_id = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  public_subnets = module.vpc.public_subnets
  internet_gateway_id = module.internet_gateway.internet_gateway_id
  nat_gateway_id = module.nat_gateway.nat_gateway_id

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

