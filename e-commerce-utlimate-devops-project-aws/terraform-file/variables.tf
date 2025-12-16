variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "three-tier-vpc"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "main-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones must be specified for high availability."
  }
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "database_subnets" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway instead of one per AZ"
  type        = bool
  default     = false
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in VPC"
  type        = bool
  default     = true
}

variable "enable_flow_log" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_log_destination_type" {
  description = "Type of flow log destination (cloud-watch-logs or s3)"
  type        = string
  default     = "s3"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "DevOps-Team"
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

# Bastion Host Variables
variable "bastion_instance_type" {
  description = "Instance type for bastion host"
  type        = string
  default     = "t3a.large"
}

variable "bastion_root_volume_size" {
  description = "Root volume size for bastion host in GB"
  type        = number
  default     = 50
}

variable "bastion_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "bastion_create_key_pair" {
  description = "Whether to create a new key pair for bastion host"
  type        = bool
  default     = true
}

variable "bastion_public_key" {
  description = "Public key for bastion host SSH access"
  type        = string
  default     = ""
}

variable "bastion_existing_key_name" {
  description = "Name of existing key pair for bastion host"
  type        = string
  default     = ""
}

variable "bastion_associate_public_ip" {
  description = "Whether to associate an Elastic IP to bastion host"
  type        = bool
  default     = true
}

variable "bastion_enable_ssm_access" {
  description = "Enable SSM Session Manager access for bastion host"
  type        = bool
  default     = false
}

# EKS Variables
variable "create_eks_cluster" {
  description = "Whether to create EKS cluster"
  type        = bool
  default     = false
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = ""
}

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.32"

  validation {
    condition     = can(regex("^1\\.(2[8-9]|3[0-9])$", var.eks_cluster_version))
    error_message = "EKS cluster version must be 1.28 or higher."
  }
}

variable "eks_cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "eks_cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = false
}

variable "eks_cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_node_groups" {
  description = "Map of EKS managed node group definitions"
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    scaling_config = object({
      desired_size = number
      max_size     = number
      min_size     = number
    })
    disk_size = optional(number, 50)
    ami_type  = optional(string, "AL2_x86_64")
    labels    = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = {}
}

variable "eks_enable_irsa" {
  description = "Enable IAM Roles for Service Accounts"
  type        = bool
  default     = true
}

variable "eks_install_addons" {
  description = "Install EKS managed addons"
  type        = bool
  default     = false
}
