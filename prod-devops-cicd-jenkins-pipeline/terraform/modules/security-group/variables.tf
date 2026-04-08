variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block — used for internal-only ingress rules"
  type        = string
}

# MANUAL: Set to your bastion/VPN/corporate CIDR for admin access.
# Example: "10.10.0.0/16" for a VPN range, or "203.0.113.0/32" for a bastion IP.
variable "admin_cidr" {
  description = "CIDR allowed to access Jenkins UI (8080) and SonarQube UI (9000)"
  type        = string
  default     = "10.0.0.0/8" # MANUAL: restrict to your actual admin CIDR
}

variable "tags" {
  description = "Additional tags to merge into all resources"
  type        = map(string)
  default     = {}
}
