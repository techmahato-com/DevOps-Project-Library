output "instance_id" {
  description = "ID of the bastion host instance"
  value       = aws_instance.bastion.id
}

output "instance_arn" {
  description = "ARN of the bastion host instance"
  value       = aws_instance.bastion.arn
}

output "public_ip" {
  description = "Public IP of the bastion host"
  value       = var.associate_public_ip ? aws_eip.bastion[0].public_ip : aws_instance.bastion.public_ip
}

output "private_ip" {
  description = "Private IP of the bastion host"
  value       = aws_instance.bastion.private_ip
}

output "security_group_id" {
  description = "ID of the bastion host security group"
  value       = aws_security_group.bastion.id
}

output "key_pair_name" {
  description = "Name of the key pair used"
  value       = var.create_key_pair ? aws_key_pair.bastion[0].key_name : var.existing_key_name
}

output "ssh_command" {
  description = "SSH command to connect to bastion host"
  value       = "ssh -i ~/.ssh/${var.create_key_pair ? aws_key_pair.bastion[0].key_name : var.existing_key_name}.pem ubuntu@${var.associate_public_ip ? aws_eip.bastion[0].public_ip : aws_instance.bastion.public_ip}"
}
