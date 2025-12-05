# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# S3 bucket for VPC Flow Logs
resource "aws_s3_bucket" "vpc_flow_logs" {
  count  = var.enable_flow_log && var.flow_log_destination_type == "s3" ? 1 : 0
  bucket = "${var.project_name}-${var.environment}-vpc-flow-logs-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "vpc_flow_logs" {
  count  = var.enable_flow_log && var.flow_log_destination_type == "s3" ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_logs" {
  count  = var.enable_flow_log && var.flow_log_destination_type == "s3" ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "vpc_flow_logs" {
  count  = var.enable_flow_log && var.flow_log_destination_type == "s3" ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

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
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs              = var.availability_zones
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  database_subnets = var.database_subnets

  # NAT Gateway configuration
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
  
  # VPN Gateway
  enable_vpn_gateway = var.enable_vpn_gateway

  # DNS configuration
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # Database subnet group
  create_database_subnet_group = true
  database_subnet_group_name   = "${var.project_name}-${var.environment}-db-subnet-group"

  # VPC Flow Logs
  enable_flow_log                      = var.enable_flow_log
  create_flow_log_cloudwatch_iam_role  = var.flow_log_destination_type == "cloud-watch-logs"
  create_flow_log_cloudwatch_log_group = var.flow_log_destination_type == "cloud-watch-logs"
  flow_log_destination_type            = var.flow_log_destination_type
  flow_log_destination_arn             = var.enable_flow_log && var.flow_log_destination_type == "s3" ? aws_s3_bucket.vpc_flow_logs[0].arn : null

  # Tags
  tags = local.common_tags

  public_subnet_tags = merge(
    local.common_tags,
    {
      Type = "Public"
      Tier = "Web"
    }
  )

  private_subnet_tags = merge(
    local.common_tags,
    {
      Type = "Private"
      Tier = "Application"
    }
  )

  database_subnet_tags = merge(
    local.common_tags,
    {
      Type = "Database"
      Tier = "Database"
    }
  )

  public_route_table_tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-public-rt"
    }
  )

  private_route_table_tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-private-rt"
    }
  )

  database_route_table_tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-database-rt"
    }
  )

  igw_tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-igw"
    }
  )

  nat_gateway_tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-nat"
    }
  )

  nat_eip_tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-nat-eip"
    }
  )
}
