output "jenkins_role_arn" {
  description = "ARN of the Jenkins IAM role"
  value       = aws_iam_role.jenkins.arn
}

output "jenkins_instance_profile_name" {
  description = "Name of the Jenkins EC2 instance profile"
  value       = aws_iam_instance_profile.jenkins.name
}

output "sonarqube_role_arn" {
  description = "ARN of the SonarQube IAM role"
  value       = aws_iam_role.sonarqube.arn
}

output "sonarqube_instance_profile_name" {
  description = "Name of the SonarQube EC2 instance profile"
  value       = aws_iam_instance_profile.sonarqube.name
}
