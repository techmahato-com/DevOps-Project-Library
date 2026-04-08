variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "List of AZs to deploy subnets into (must match subnet CIDR count)"
  type        = list(string)
}

# NAT mode: "gateway" = managed NAT Gateway (HA, higher cost)
#           "instance" = single NAT EC2 (lower cost, suitable for dev)
variable "nat_mode" {
  description = "NAT mode: 'gateway' or 'instance'"
  type        = string
  default     = "gateway"

  validation {
    condition     = contains(["gateway", "instance"], var.nat_mode)
    error_message = "nat_mode must be 'gateway' or 'instance'."
  }
}

# MANUAL: Set to a valid NAT AMI for your region when nat_mode = "instance"
# Recommended: fck-nat (https://fck-nat.dev) or AWS NAT AMI
variable "nat_instance_ami" {
  description = "AMI ID for NAT instance (required when nat_mode = 'instance')"
  type        = string
  default     = "" # MANUAL: replace with region-specific NAT AMI
}

variable "nat_instance_type" {
  description = "Instance type for NAT instance (used when nat_mode = 'instance')"
  type        = string
  default     = "t3.micro"
}

variable "tags" {
  description = "Additional tags to merge into all resources"
  type        = map(string)
  default     = {}
}
