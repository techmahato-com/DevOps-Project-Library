# Data source for Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for Bastion Host
resource "aws_security_group" "bastion" {
  name_prefix = "${var.name_prefix}-bastion-"
  vpc_id      = var.vpc_id
  description = "Security group for bastion host"

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "SSH access"
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bastion-sg"
  })
}

# Key Pair
resource "aws_key_pair" "bastion" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = "${var.name_prefix}-bastion-key"
  public_key = var.public_key

  tags = var.tags
}

# IAM Role for SSM Access
resource "aws_iam_role" "bastion_ssm" {
  count = var.enable_ssm_access ? 1 : 0
  name  = "${var.name_prefix}-bastion-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach SSM Managed Instance Core policy
resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  count      = var.enable_ssm_access ? 1 : 0
  role       = aws_iam_role.bastion_ssm[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile
resource "aws_iam_instance_profile" "bastion_ssm" {
  count = var.enable_ssm_access ? 1 : 0
  name  = "${var.name_prefix}-bastion-ssm-profile"
  role  = aws_iam_role.bastion_ssm[0].name

  tags = var.tags
}

# Bastion Host EC2 Instance
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.create_key_pair ? aws_key_pair.bastion[0].key_name : var.existing_key_name
  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = var.subnet_id
  iam_instance_profile   = var.enable_ssm_access ? aws_iam_instance_profile.bastion_ssm[0].name : null

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
    tags = merge(var.tags, {
      Name = "${var.name_prefix}-bastion-root-volume"
    })
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    hostname = "${var.name_prefix}-bastion"
  }))

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bastion-host"
    Type = "Bastion"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP for Bastion Host
resource "aws_eip" "bastion" {
  count    = var.associate_public_ip ? 1 : 0
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bastion-eip"
  })

  depends_on = [aws_instance.bastion]
}
