locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      Role        = var.role
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_instance" "this" {
  count = var.create ? 1 : 0

  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = var.iam_instance_profile != "" ? var.iam_instance_profile : null

  # Prefer SSM Session Manager for access — set key_name only if SSH is required
  key_name = var.key_name != "" ? var.key_name : null

  user_data                   = var.user_data != "" ? var.user_data : null
  user_data_replace_on_change = false # set to true to force instance replacement on script changes

  # gp3 root volume — better IOPS/throughput than gp2 at same cost; encrypted at rest
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size_gb
    encrypted             = true
    delete_on_termination = true

    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-${var.role}-root-vol"
    })
  }

  # All instances are in private subnets — no public IP
  associate_public_ip_address = false

  # IMDSv2 enforced — prevents SSRF-based metadata credential theft
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-${var.role}" })

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}
