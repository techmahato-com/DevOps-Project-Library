variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB will be created"
  type        = string
}

# Use public subnets for internet-facing ALB, private subnets for internal ALB
variable "subnet_ids" {
  description = "List of subnet IDs for the ALB (min 2 AZs required)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the ALB"
  type        = list(string)
}

# Set to false for an internal (private) ALB — recommended for this platform
variable "internal" {
  description = "Set to true for internal ALB, false for internet-facing"
  type        = bool
  default     = true
}

# MANUAL: Provide a valid ACM certificate ARN for HTTPS listener
variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener (required for production)"
  type        = string
  default     = "" # MANUAL: set to your ACM certificate ARN
}

variable "target_port" {
  description = "Port on the target instances (e.g. 8080 for Jenkins)"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "Health check path for the target group"
  type        = string
  default     = "/login"
}

variable "tags" {
  description = "Additional tags to merge into all resources"
  type        = map(string)
  default     = {}
}
