locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# ─── Jenkins IAM Role ─────────────────────────────────────────────────────────
# Least-privilege: ECR push/pull, CloudWatch Logs, SSM Session Manager
# No static access keys — credentials come from instance profile
resource "aws_iam_role" "jenkins" {
  name = "${local.name_prefix}-role-jenkins"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-role-jenkins" })
}

# ECR: authenticate, push, and pull images
resource "aws_iam_policy" "jenkins_ecr" {
  name        = "${local.name_prefix}-policy-jenkins-ecr"
  description = "Allow Jenkins to authenticate and push/pull ECR images"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ECRAuth"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*" # GetAuthorizationToken does not support resource-level restriction
      },
      {
        Sid    = "ECRPushPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = var.ecr_repository_arns
      }
    ]
  })
}

# CloudWatch Logs: write Jenkins build logs for observability
resource "aws_iam_policy" "jenkins_cloudwatch" {
  name        = "${local.name_prefix}-policy-jenkins-cw"
  description = "Allow Jenkins to write CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "CWLogs"
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ]
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_ecr" {
  role       = aws_iam_role.jenkins.name
  policy_arn = aws_iam_policy.jenkins_ecr.arn
}

resource "aws_iam_role_policy_attachment" "jenkins_cloudwatch" {
  role       = aws_iam_role.jenkins.name
  policy_arn = aws_iam_policy.jenkins_cloudwatch.arn
}

# SSM Session Manager — shell access without SSH key management
resource "aws_iam_role_policy_attachment" "jenkins_ssm" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# S3 read access for bootstrap scripts bucket — used by SSM RunShellScript
resource "aws_iam_role_policy" "jenkins_s3_scripts" {
  name = "s3-scripts-read"
  role = aws_iam_role.jenkins.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "arn:aws:s3:::${var.scripts_bucket_name}/scripts/*"
    }]
  })
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "${local.name_prefix}-profile-jenkins"
  role = aws_iam_role.jenkins.name

  tags = local.common_tags
}

# ─── SonarQube IAM Role ───────────────────────────────────────────────────────
# Minimal: SSM Session Manager only — SonarQube does not need AWS API access
resource "aws_iam_role" "sonarqube" {
  name = "${local.name_prefix}-role-sonarqube"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-role-sonarqube" })
}

resource "aws_iam_role_policy_attachment" "sonarqube_ssm" {
  role       = aws_iam_role.sonarqube.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# S3 read access for bootstrap scripts bucket
resource "aws_iam_role_policy" "sonarqube_s3_scripts" {
  name = "s3-scripts-read"
  role = aws_iam_role.sonarqube.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = "arn:aws:s3:::${var.scripts_bucket_name}/scripts/*"
    }]
  })
}

resource "aws_iam_instance_profile" "sonarqube" {
  name = "${local.name_prefix}-profile-sonarqube"
  role = aws_iam_role.sonarqube.name

  tags = local.common_tags
}
