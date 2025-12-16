output "vpc_flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = var.enable_flow_log ? aws_flow_log.vpc_flow_log[0].id : null
}

output "flow_logs_s3_bucket_id" {
  description = "ID of the S3 bucket for VPC Flow Logs"
  value       = var.enable_flow_log && var.flow_log_destination_type == "s3" ? aws_s3_bucket.vpc_flow_logs[0].id : null
}

output "flow_logs_s3_bucket_arn" {
  description = "ARN of the S3 bucket for VPC Flow Logs"
  value       = var.enable_flow_log && var.flow_log_destination_type == "s3" ? aws_s3_bucket.vpc_flow_logs[0].arn : null
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for VPC Flow Logs"
  value       = var.enable_flow_log && var.flow_log_destination_type == "cloud-watch-logs" ? aws_cloudwatch_log_group.vpc_flow_logs[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for VPC Flow Logs"
  value       = var.enable_flow_log && var.flow_log_destination_type == "cloud-watch-logs" ? aws_cloudwatch_log_group.vpc_flow_logs[0].arn : null
}

output "flow_log_iam_role_arn" {
  description = "ARN of the IAM role for VPC Flow Logs"
  value       = var.enable_flow_log && var.flow_log_destination_type == "cloud-watch-logs" ? aws_iam_role.flow_log[0].arn : null
}
