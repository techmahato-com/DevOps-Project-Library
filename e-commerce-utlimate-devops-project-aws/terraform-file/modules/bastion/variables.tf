variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where bastion host will be created"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID for bastion host"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3a.large"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 50
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to SSH to bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "create_key_pair" {
  description = "Whether to create a new key pair"
  type        = bool
  default     = true
}

variable "public_key" {
  description = "Public key for SSH access (required if create_key_pair is true)"
  type        = string
  default     = ""
}

variable "existing_key_name" {
  description = "Name of existing key pair (used if create_key_pair is false)"
  type        = string
  default     = ""
}

variable "associate_public_ip" {
  description = "Whether to associate an Elastic IP"
  type        = bool
  default     = true
}

variable "enable_ssm_access" {
  description = "Enable SSM Session Manager access"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
