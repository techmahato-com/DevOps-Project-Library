# Three-Tier VPC Architecture with Terraform

Production-ready Terraform infrastructure for deploying a highly available 3-tier VPC architecture on AWS using custom modules.

## 📋 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Project Structure](#-project-structure)
- [Environment Configuration](#-environment-configuration)
- [Deployment Guide](#-deployment-guide)
- [Custom Modules](#-custom-modules)
- [Configuration Reference](#-configuration-reference)
- [Outputs](#-outputs)
- [Best Practices](#-best-practices)
- [Troubleshooting](#-troubleshooting)

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    VPC (Environment Specific CIDR)             │
├─────────────────────────────────────────────────────────────────┤
│  AZ-1a                              │  AZ-1b                    │
├─────────────────────────────────────┼───────────────────────────┤
│  Public Subnet                      │  Public Subnet            │
│  ┌─────────────────────────────────┐│  ┌─────────────────────────┐ │
│  │ Web Tier                        ││  │ Web Tier                │ │
│  │ • ALB                           ││  │ • ALB                   │ │
│  │ • Bastion Host                  ││  │ • Bastion Host          │ │
│  │ • NAT Gateway                   ││  │ • NAT Gateway (Optional)│ │
│  └─────────────────────────────────┘│  └─────────────────────────┘ │
├─────────────────────────────────────┼───────────────────────────┤
│  Private Subnet                     │  Private Subnet           │
│  ┌─────────────────────────────────┐│  ┌─────────────────────────┐ │
│  │ Application Tier                ││  │ Application Tier        │ │
│  │ • EC2 Instances                 ││  │ • EC2 Instances         │ │
│  │ • ECS/Fargate                   ││  │ • ECS/Fargate           │ │
│  │ • Lambda Functions              ││  │ • Lambda Functions      │ │
│  └─────────────────────────────────┘│  └─────────────────────────┘ │
├─────────────────────────────────────┼───────────────────────────┤
│  Database Subnet                    │  Database Subnet          │
│  ┌─────────────────────────────────┐│  ┌─────────────────────────┐ │
│  │ Data Tier                       ││  │ Data Tier               │ │
│  │ • RDS (Multi-AZ)                ││  │ • RDS (Multi-AZ)        │ │
│  │ • ElastiCache                   ││  │ • ElastiCache           │ │
│  │ • DocumentDB                    ││  │ • DocumentDB            │ │
│  └─────────────────────────────────┘│  └─────────────────────────┘ │
└─────────────────────────────────────┴───────────────────────────────┘
```

### Key Features

- **High Availability**: Multi-AZ deployment across 2 availability zones
- **Security**: Network isolation with proper subnet segregation
- **Scalability**: Configurable CIDR blocks and subnet sizing
- **Cost Optimization**: Environment-specific NAT Gateway configuration
- **Monitoring**: VPC Flow Logs with S3 or CloudWatch destinations
- **Custom Modules**: Self-contained, reusable Terraform modules

## 📋 Prerequisites

### Required Tools

- **Terraform** >= 1.6.0
- **AWS CLI** >= 2.0.0
- **jq** (optional, for enhanced script output)
- **make** (optional, for using Makefile commands)

### AWS Requirements

- AWS Account with appropriate permissions
- AWS CLI configured with credentials
- IAM permissions for VPC, EC2, S3, and CloudWatch resources

### Installation Commands

```bash
# Install Terraform (Ubuntu/Debian)
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# Install jq
sudo apt install jq

# Configure AWS CLI
aws configure
```

## 🚀 Quick Start

### 1. Initial Setup

```bash
# Clone the repository
git clone <repository-url>
cd three-tier-vpc-architecture

# Run setup script
./scripts/setup.sh

# Or use Makefile
make setup
```

### 2. Configure Variables

```bash
# Copy and edit terraform.tfvars
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# Review environment-specific configurations
ls environments/
```

### 3. Deploy Infrastructure

```bash
# Plan deployment
./scripts/deploy.sh dev --plan-only

# Deploy development environment
./scripts/deploy.sh dev

# Or use Makefile
make plan-dev
make deploy-dev
```

## 📁 Project Structure

```
three-tier-vpc-architecture/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── versions.tf                # Provider requirements
├── terraform.tfvars.example   # Example variables file
├── backend.tf.example         # Example backend configuration
├── Makefile                   # Automation commands
├── README.md                  # This file
├── environments/              # Environment-specific configurations
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
├── modules/                   # Custom Terraform modules
│   ├── vpc/                   # VPC module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── vpc-flow-logs/         # VPC Flow Logs module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── scripts/                   # Deployment scripts
    ├── setup.sh               # Initial setup
    ├── deploy.sh              # Universal deployment script
    └── destroy.sh             # Universal destroy script
```

## 🌍 Environment Configuration

### Development Environment

```hcl
# environments/dev.tfvars
aws_region = "us-east-1"
environment = "dev"
vpc_cidr = "10.0.0.0/16"
single_nat_gateway = true      # Cost optimization
enable_flow_log = false        # Optional for dev
```

### Staging Environment

```hcl
# environments/staging.tfvars
aws_region = "us-east-1"
environment = "staging"
vpc_cidr = "10.1.0.0/16"
single_nat_gateway = false     # High availability
enable_flow_log = true         # Monitoring enabled
```

### Production Environment

```hcl
# environments/prod.tfvars
aws_region = "us-east-1"
environment = "prod"
vpc_cidr = "10.2.0.0/16"
single_nat_gateway = false     # High availability
enable_flow_log = true         # Required for production
```

## 🚀 Deployment Guide

### Using Scripts (Recommended)

#### Deploy Environment

```bash
# Development
./scripts/deploy.sh dev

# Staging
./scripts/deploy.sh staging

# Production (with extra confirmation)
./scripts/deploy.sh prod

# Plan only (no deployment)
./scripts/deploy.sh prod --plan-only

# Auto-approve (skip confirmations)
./scripts/deploy.sh dev --auto-approve
```

#### Destroy Environment

```bash
# Development
./scripts/destroy.sh dev

# Production (with extra confirmation)
./scripts/destroy.sh prod

# Plan destroy only
./scripts/destroy.sh prod --plan-only
```

### Using Makefile

```bash
# Setup and deployment
make setup
make plan-dev
make deploy-dev

# Production deployment
make plan-prod
make deploy-prod

# Destroy environments
make destroy-dev
make destroy-prod

# Utility commands
make outputs
make clean
```

### Manual Deployment

```bash
# Initialize
terraform init

# Plan
terraform plan -var-file="environments/dev.tfvars"

# Apply
terraform apply -var-file="environments/dev.tfvars"

# Destroy
terraform destroy -var-file="environments/dev.tfvars"
```

## 🧩 Custom Modules

### VPC Module (`modules/vpc/`)

Creates the core VPC infrastructure:

- VPC with configurable CIDR
- Public, private, and database subnets
- Internet Gateway
- NAT Gateways (configurable)
- Route tables and associations
- Database subnet group

**Usage:**
```hcl
module "vpc" {
  source = "./modules/vpc"
  
  vpc_name           = "my-vpc"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets    = ["10.0.11.0/24", "10.0.12.0/24"]
  database_subnets   = ["10.0.21.0/24", "10.0.22.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = false
  
  tags = {
    Environment = "production"
  }
}
```

### VPC Flow Logs Module (`modules/vpc-flow-logs/`)

Manages VPC Flow Logs configuration:

- S3 bucket with encryption and versioning
- CloudWatch log group
- IAM roles and policies
- Configurable destination (S3 or CloudWatch)

**Usage:**
```hcl
module "vpc_flow_logs" {
  source = "./modules/vpc-flow-logs"
  
  enable_flow_log           = true
  flow_log_destination_type = "s3"
  vpc_id                   = module.vpc.vpc_id
  s3_bucket_name           = "my-vpc-flow-logs-bucket"
  
  tags = {
    Environment = "production"
  }
}
```

## ⚙️ Configuration Reference

### Core Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | string | `"us-east-1"` | AWS region for resources |
| `environment` | string | `"dev"` | Environment name |
| `project_name` | string | `"three-tier-vpc"` | Project name |
| `vpc_cidr` | string | `"10.0.0.0/16"` | VPC CIDR block |
| `availability_zones` | list(string) | `["us-east-1a", "us-east-1b"]` | Availability zones |

### Subnet Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `public_subnets` | list(string) | `["10.0.1.0/24", "10.0.2.0/24"]` | Public subnet CIDRs |
| `private_subnets` | list(string) | `["10.0.11.0/24", "10.0.12.0/24"]` | Private subnet CIDRs |
| `database_subnets` | list(string) | `["10.0.21.0/24", "10.0.22.0/24"]` | Database subnet CIDRs |

### NAT Gateway Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_nat_gateway` | bool | `true` | Enable NAT Gateway |
| `single_nat_gateway` | bool | `false` | Use single NAT Gateway |

### VPC Flow Logs

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_flow_log` | bool | `true` | Enable VPC Flow Logs |
| `flow_log_destination_type` | string | `"s3"` | Destination type (s3/cloud-watch-logs) |

## 📤 Outputs

### VPC Outputs

- `vpc_id` - VPC ID
- `vpc_arn` - VPC ARN
- `vpc_cidr_block` - VPC CIDR block

### Subnet Outputs

- `public_subnets` - Public subnet IDs
- `private_subnets` - Private subnet IDs
- `database_subnets` - Database subnet IDs
- `database_subnet_group` - Database subnet group ID

### Gateway Outputs

- `igw_id` - Internet Gateway ID
- `nat_ids` - NAT Gateway IDs
- `nat_public_ips` - NAT Gateway public IPs

### Flow Logs Outputs

- `vpc_flow_log_id` - VPC Flow Log ID
- `flow_logs_s3_bucket_arn` - S3 bucket ARN (if S3 destination)

## 🎯 Best Practices

### Security

- Use different CIDR ranges for each environment
- Enable VPC Flow Logs in production
- Implement least privilege IAM policies
- Use private subnets for application and database tiers

### Cost Optimization

- Use single NAT Gateway in development environments
- Disable VPC Flow Logs in development if not needed
- Use appropriate instance types for NAT Gateways

### High Availability

- Deploy across multiple availability zones
- Use multiple NAT Gateways in production
- Implement proper health checks

### Operational Excellence

- Use remote state management (S3 + DynamoDB)
- Implement proper tagging strategy
- Use environment-specific configurations
- Automate deployments with scripts

## 🔧 Troubleshooting

### Common Issues

#### Terraform Initialization Fails

```bash
# Clear Terraform cache
rm -rf .terraform .terraform.lock.hcl

# Re-initialize
terraform init
```

#### AWS Credentials Issues

```bash
# Check credentials
aws sts get-caller-identity

# Reconfigure if needed
aws configure
```

#### CIDR Conflicts

Ensure each environment uses different CIDR ranges:
- Dev: `10.0.0.0/16`
- Staging: `10.1.0.0/16`
- Prod: `10.2.0.0/16`

#### Resource Limits

Check AWS service limits:
- VPCs per region: 5 (default)
- NAT Gateways per AZ: 5 (default)
- Elastic IPs: 5 (default)

### Getting Help

1. Check Terraform documentation
2. Review AWS VPC documentation
3. Check CloudTrail logs for API errors
4. Use `terraform plan` to preview changes
5. Enable debug logging: `export TF_LOG=DEBUG`

## 📝 Remote State Setup

For production environments, configure remote state:

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "vpc/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

Create the S3 bucket and DynamoDB table:

```bash
# Create S3 bucket
aws s3 mb s3://your-terraform-state-bucket

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Create DynamoDB table
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Made with ❤️ for DevOps Engineers**
