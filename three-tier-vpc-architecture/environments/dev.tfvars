# Development Environment Configuration
aws_region = "us-east-1"

# Project Configuration
project_name = "three-tier-vpc"
environment  = "dev"
owner        = "DevOps-Team"

# VPC Configuration
vpc_name = "dev-vpc"
vpc_cidr = "10.0.0.0/16"

# Availability Zones
availability_zones = ["us-east-1a", "us-east-1b"]

# Subnet Configuration
public_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets  = ["10.0.11.0/24", "10.0.12.0/24"]
database_subnets = ["10.0.21.0/24", "10.0.22.0/24"]

# NAT Gateway Configuration - Cost Optimized
enable_nat_gateway = true
single_nat_gateway = true  # Single NAT for cost savings

# DNS Configuration
enable_dns_hostnames = true
enable_dns_support   = true

# VPN Gateway
enable_vpn_gateway = false

# VPC Flow Logs - Optional for dev
enable_flow_log            = false
flow_log_destination_type  = "s3"

# Development Tags
tags = {
  Environment = "Development"
  CostCenter  = "Engineering"
  AutoShutdown = "Enabled"
}
