variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, prod)"
  type        = string
}

variable "ecr_repository_arns" {
  description = "List of ECR repository ARNs Jenkins can push/pull images to/from"
  type        = list(string)
  default     = ["*"]
}

# S3 bucket name where bootstrap scripts are stored (for SSM-based installs)
variable "scripts_bucket_name" {
  description = "S3 bucket name that holds bootstrap scripts under /scripts/*"
  type        = string
}

variable "tags" {
  description = "Additional tags to merge into all resources"
  type        = map(string)
  default     = {}
}
