output "instance_id" {
  description = "EC2 instance ID (null if create = false)"
  value       = var.create ? aws_instance.this[0].id : null
}

output "private_ip" {
  description = "Private IP address of the instance (null if create = false)"
  value       = var.create ? aws_instance.this[0].private_ip : null
}

output "instance_arn" {
  description = "ARN of the EC2 instance (null if create = false)"
  value       = var.create ? aws_instance.this[0].arn : null
}
