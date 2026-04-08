variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, prod)"
  type        = string
}

variable "repository_names" {
  description = "List of repository short names to create (prefixed with project_name-environment)"
  type        = list(string)
  default     = ["app"]
}

# MUTABLE allows overwriting tags (useful in dev); IMMUTABLE enforces tag uniqueness (recommended for prod)
variable "image_tag_mutability" {
  description = "Image tag mutability: MUTABLE or IMMUTABLE"
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be 'MUTABLE' or 'IMMUTABLE'."
  }
}

variable "lifecycle_policy_max_images" {
  description = "Maximum number of tagged images to retain per repository"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Additional tags to merge into all resources"
  type        = map(string)
  default     = {}
}
