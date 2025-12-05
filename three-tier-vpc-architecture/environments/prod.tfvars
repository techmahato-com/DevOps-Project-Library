# Production Environment Configuration
aws_region = "us-east-1"

# Project Configuration
project_name = "three-tier-vpc"
environment  = "prod"
owner        = "DevOps-Team"

# VPC Configuration
vpc_name = "prod-vpc"
vpc_cidr = "10.2.0.0/16"

# Availability Zones
availability_zones = ["us-east-1a", "us-east-1b"]

# Subnet Configuration
public_subnets   = ["10.2.1.0/24", "10.2.2.0/24"]
private_subnets  = ["10.2.11.0/24", "10.2.12.0/24"]
database_subnets = ["10.2.21.0/24", "10.2.22.0/24"]

# NAT Gateway Configuration - High Availability
enable_nat_gateway = true
single_nat_gateway = false  # Multiple NAT Gateways for HA

# DNS Configuration
enable_dns_hostnames = true
enable_dns_support   = true

# VPN Gateway
enable_vpn_gateway = false

# VPC Flow Logs - Required for production
enable_flow_log            = true
flow_log_destination_type  = "s3"

# Production Tags
tags = {
  Environment = "Production"
  CostCenter  = "Engineering"
  Backup      = "Required"
  Compliance  = "SOC2"
  Monitoring  = "Required"
}
