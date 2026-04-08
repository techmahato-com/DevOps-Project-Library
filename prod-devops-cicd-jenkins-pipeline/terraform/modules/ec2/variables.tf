variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, prod)"
  type        = string
}

variable "role" {
  description = "Logical role of this instance (e.g. jenkins, sonarqube, agent)"
  type        = string
}

# MANUAL: Set to a valid Amazon Linux 2023 AMI for your region.
# Find latest: aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-*-x86_64"
variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "subnet_id" {
  description = "Subnet ID to launch the instance in (use private subnet)"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to attach"
  type        = list(string)
}

variable "iam_instance_profile" {
  description = "IAM instance profile name to attach"
  type        = string
  default     = ""
}

# Optional: leave empty to use SSM Session Manager instead of SSH keys
variable "key_name" {
  description = "EC2 key pair name (optional — prefer SSM Session Manager)"
  type        = string
  default     = ""
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GB (gp3, encrypted)"
  type        = number
  default     = 30
}

variable "user_data" {
  description = "Raw shell script content for EC2 user_data (Terraform base64-encodes it automatically)"
  type        = string
  default     = ""
}

variable "create" {
  description = "Set to false to skip creating this instance (useful for optional agent)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to merge into all resources"
  type        = map(string)
  default     = {}
}
