# S3 bucket for VPC Flow Logs
resource "aws_s3_bucket" "vpc_flow_logs" {
  count  = var.enable_flow_log && var.flow_log_destination_type == "s3" ? 1 : 0
  bucket = var.s3_bucket_name
}

resource "aws_s3_bucket_versioning" "vpc_flow_logs" {
  count  = var.enable_flow_log && var.flow_log_destination_type == "s3" ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_logs" {
  count  = var.enable_flow_log && var.flow_log_destination_type == "s3" ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "vpc_flow_logs" {
  count  = var.enable_flow_log && var.flow_log_destination_type == "s3" ? 1 : 0
  bucket = aws_s3_bucket.vpc_flow_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count             = var.enable_flow_log && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0
  name              = var.cloudwatch_log_group_name
  retention_in_days = var.cloudwatch_log_retention_days

  tags = var.tags
}

# IAM role for VPC Flow Logs to CloudWatch
resource "aws_iam_role" "flow_log" {
  count = var.enable_flow_log && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0
  name  = var.flow_log_iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_log" {
  count = var.enable_flow_log && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0
  name  = "flow-log-delivery-policy"
  role  = aws_iam_role.flow_log[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# VPC Flow Log
resource "aws_flow_log" "vpc_flow_log" {
  count                = var.enable_flow_log ? 1 : 0
  iam_role_arn         = var.flow_log_destination_type == "cloud-watch-logs" ? aws_iam_role.flow_log[0].arn : null
  log_destination      = var.flow_log_destination_type == "s3" ? aws_s3_bucket.vpc_flow_logs[0].arn : aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  log_destination_type = var.flow_log_destination_type
  traffic_type         = var.flow_log_traffic_type
  vpc_id               = var.vpc_id

  tags = var.tags
}
