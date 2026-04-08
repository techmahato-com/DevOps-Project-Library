output "repository_urls" {
  description = "Map of repository short name to ECR repository URL"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of repository short name to ECR repository ARN"
  value       = { for k, v in aws_ecr_repository.this : k => v.arn }
}

output "repository_arns_list" {
  description = "Flat list of ECR repository ARNs (for IAM policy attachment)"
  value       = [for v in aws_ecr_repository.this : v.arn]
}
