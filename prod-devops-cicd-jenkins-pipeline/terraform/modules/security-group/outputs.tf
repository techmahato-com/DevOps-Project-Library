output "jenkins_sg_id" {
  description = "Security group ID for Jenkins controller"
  value       = aws_security_group.jenkins.id
}

output "sonarqube_sg_id" {
  description = "Security group ID for SonarQube"
  value       = aws_security_group.sonarqube.id
}

output "jenkins_agent_sg_id" {
  description = "Security group ID for optional Jenkins agent nodes"
  value       = aws_security_group.jenkins_agent.id
}

output "alb_sg_id" {
  description = "Security group ID for the internal ALB placeholder"
  value       = aws_security_group.alb.id
}

output "nexus_sg_id" {
  description = "Security group ID for Nexus"
  value       = aws_security_group.nexus.id
}

output "postgres_sg_id" {
  description = "Security group ID for PostgreSQL"
  value       = aws_security_group.postgres.id
}
