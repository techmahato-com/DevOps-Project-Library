# Staging Environment Configuration
aws_region = "us-east-1"

# Project Configuration
project_name = "three-tier-vpc"
environment  = "staging"
owner        = "DevOps-Team"

# VPC Configuration
vpc_name = "staging-vpc"
vpc_cidr = "10.1.0.0/16"

# Availability Zones
availability_zones = ["us-east-1a", "us-east-1b"]

# Subnet Configuration
public_subnets   = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnets  = ["10.1.11.0/24", "10.1.12.0/24"]
database_subnets = ["10.1.21.0/24", "10.1.22.0/24"]

# NAT Gateway Configuration - Production-like
enable_nat_gateway = true
single_nat_gateway = false  # Multiple NAT for testing HA

# DNS Configuration
enable_dns_hostnames = true
enable_dns_support   = true

# VPN Gateway
enable_vpn_gateway = false

# VPC Flow Logs - Enabled for testing
enable_flow_log            = true
flow_log_destination_type  = "s3"

# Staging Tags
tags = {
  Environment = "Staging"
  CostCenter  = "Engineering"
  Testing     = "Required"
}
