# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# Subnet Outputs
output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = aws_subnet.database[*].id
}

output "public_subnet_arns" {
  description = "List of ARNs of public subnets"
  value       = aws_subnet.public[*].arn
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = aws_subnet.private[*].arn
}

output "database_subnet_arns" {
  description = "List of ARNs of database subnets"
  value       = aws_subnet.database[*].arn
}

# Route Table Outputs
output "public_route_table_ids" {
  description = "List of IDs of the public route tables"
  value       = [aws_route_table.public.id]
}

output "private_route_table_ids" {
  description = "List of IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

output "database_route_table_ids" {
  description = "List of IDs of the database route tables"
  value       = [aws_route_table.database.id]
}

# Internet Gateway Outputs
output "igw_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "igw_arn" {
  description = "ARN of the Internet Gateway"
  value       = aws_internet_gateway.main.arn
}

# NAT Gateway Outputs
output "nat_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = aws_eip.nat[*].public_ip
}

output "natgw_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

# Database Subnet Group
output "database_subnet_group" {
  description = "ID of database subnet group"
  value       = var.create_database_subnet_group ? aws_db_subnet_group.main[0].id : null
}

output "database_subnet_group_name" {
  description = "Name of database subnet group"
  value       = var.create_database_subnet_group ? aws_db_subnet_group.main[0].name : null
}

# Availability Zones
output "azs" {
  description = "List of availability zones"
  value       = var.availability_zones
}
