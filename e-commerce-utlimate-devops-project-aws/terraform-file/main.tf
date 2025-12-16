# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Random ID for unique resource naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Local values for common tags
locals {
  common_tags = merge(
    {
      Name        = var.vpc_name
      Environment = var.environment
      Project     = var.project_name
      Owner       = var.owner
      ManagedBy   = "Terraform"
    },
    var.tags
  )
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  vpc_name           = "${var.project_name}-${var.environment}-vpc"
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  database_subnets = var.database_subnets

  # NAT Gateway configuration
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  # DNS configuration
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # Database subnet group
  create_database_subnet_group = true
  database_subnet_group_name   = "${var.project_name}-${var.environment}-db-subnet-group"

  # Tags
  tags = local.common_tags

  public_subnet_tags = {
    Type = "Public"
    Tier = "Web"
  }

  private_subnet_tags = {
    Type = "Private"
    Tier = "Application"
  }

  database_subnet_tags = {
    Type = "Database"
    Tier = "Database"
  }
}

# VPC Flow Logs Module
module "vpc_flow_logs" {
  source = "./modules/vpc-flow-logs"

  enable_flow_log           = var.enable_flow_log
  flow_log_destination_type = var.flow_log_destination_type
  vpc_id                    = module.vpc.vpc_id

  # S3 configuration
  s3_bucket_name = var.enable_flow_log && var.flow_log_destination_type == "s3" ? "${var.project_name}-${var.environment}-vpc-flow-logs-${random_id.bucket_suffix.hex}" : ""

  # CloudWatch configuration
  cloudwatch_log_group_name = "/aws/vpc/${var.project_name}-${var.environment}/flowlogs"
  flow_log_iam_role_name    = "${var.project_name}-${var.environment}-flowlogs-role"

  tags = local.common_tags
}

# Bastion Host Module
module "bastion" {
  source = "./modules/bastion"

  name_prefix         = "${var.project_name}-${var.environment}"
  vpc_id              = module.vpc.vpc_id
  subnet_id           = module.vpc.public_subnets[0]
  instance_type       = var.bastion_instance_type
  root_volume_size    = var.bastion_root_volume_size
  allowed_cidr_blocks = var.bastion_allowed_cidr_blocks
  create_key_pair     = var.bastion_create_key_pair
  public_key          = var.bastion_public_key
  existing_key_name   = var.bastion_existing_key_name
  associate_public_ip = var.bastion_associate_public_ip
  enable_ssm_access   = var.bastion_enable_ssm_access

  tags = local.common_tags
}

# EKS Cluster Module
module "eks" {
  count  = var.create_eks_cluster ? 1 : 0
  source = "./modules/eks"

  cluster_name    = var.eks_cluster_name != "" ? var.eks_cluster_name : "${var.project_name}-${var.environment}"
  cluster_version = var.eks_cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = concat(module.vpc.private_subnets, module.vpc.public_subnets)

  cluster_endpoint_private_access      = var.eks_cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.eks_cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.eks_cluster_endpoint_public_access_cidrs

  node_groups = var.eks_node_groups

  tags = local.common_tags
}
