# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

# Subnet Outputs
output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = module.vpc.public_subnet_arns
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = module.vpc.private_subnet_arns
}

output "database_subnet_arns" {
  description = "List of ARNs of database subnets"
  value       = module.vpc.database_subnet_arns
}

# Route Table Outputs
output "public_route_table_ids" {
  description = "List of IDs of the public route tables"
  value       = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  description = "List of IDs of the private route tables"
  value       = module.vpc.private_route_table_ids
}

output "database_route_table_ids" {
  description = "List of IDs of the database route tables"
  value       = module.vpc.database_route_table_ids
}

# Internet Gateway Outputs
output "igw_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.igw_id
}

output "igw_arn" {
  description = "ARN of the Internet Gateway"
  value       = module.vpc.igw_arn
}

# NAT Gateway Outputs
output "nat_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = module.vpc.nat_ids
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}

output "natgw_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = module.vpc.natgw_ids
}

# Database Subnet Group
output "database_subnet_group" {
  description = "ID of database subnet group"
  value       = module.vpc.database_subnet_group
}

output "database_subnet_group_name" {
  description = "Name of database subnet group"
  value       = module.vpc.database_subnet_group_name
}

# Availability Zones
output "azs" {
  description = "List of availability zones"
  value       = module.vpc.azs
}

# VPC Flow Logs
output "vpc_flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = module.vpc.vpc_flow_log_id
}

output "vpc_flow_log_destination_arn" {
  description = "ARN of the destination for VPC Flow Logs"
  value       = var.enable_flow_log && var.flow_log_destination_type == "s3" ? aws_s3_bucket.vpc_flow_logs[0].arn : null
}

# S3 Bucket for Flow Logs
output "flow_logs_s3_bucket_id" {
  description = "ID of the S3 bucket for VPC Flow Logs"
  value       = var.enable_flow_log && var.flow_log_destination_type == "s3" ? aws_s3_bucket.vpc_flow_logs[0].id : null
}

output "flow_logs_s3_bucket_arn" {
  description = "ARN of the S3 bucket for VPC Flow Logs"
  value       = var.enable_flow_log && var.flow_log_destination_type == "s3" ? aws_s3_bucket.vpc_flow_logs[0].arn : null
}
