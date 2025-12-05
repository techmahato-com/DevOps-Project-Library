# Three-Tier VPC Architecture with Terraform

Production-ready Terraform infrastructure for deploying a highly available 3-tier VPC architecture on AWS.

## 📋 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Project Structure](#-project-structure)
- [Environment Configuration](#-environment-configuration)
- [Deployment Guide](#-deployment-guide)
- [Remote State Setup](#-remote-state-setup)
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

### Environment CIDR Allocation
- **Development**: `10.0.0.0/16`
- **Staging**: `10.1.0.0/16`
- **Production**: `10.2.0.0/16`

## ✅ Prerequisites

- **Terraform** >= 1.6
- **AWS CLI** configured with appropriate permissions
- **Git** for version control
- **Make** (optional, for using Makefile commands)

### Required AWS Permissions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "s3:*",
        "logs:*",
        "iam:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone <repository-url>
cd three-tier-vpc-architecture
```

### 2. Choose Deployment Method

#### Option A: Using Scripts (Recommended)
```bash
# Deploy development environment
./scripts/deploy-dev.sh

# Deploy production environment
./scripts/deploy-prod.sh
```

#### Option B: Using Makefile
```bash
# Deploy development
make deploy-dev

# Deploy production
make deploy-prod
```

#### Option C: Manual Terraform Commands
```bash
# Initialize
terraform init

# Deploy development
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

## 📁 Project Structure

```
three-tier-vpc-architecture/
├── main.tf                     # Main VPC configuration
├── variables.tf                # Variable definitions
├── outputs.tf                  # Output values
├── versions.tf                 # Provider versions
├── backend.tf.example          # Remote state template
├── terraform.tfvars.example    # Sample configuration
├── Makefile                    # Deployment shortcuts
├── README.md                   # This file
├── environments/               # Environment-specific configs
│   ├── dev.tfvars             # Development settings
│   ├── staging.tfvars         # Staging settings
│   └── prod.tfvars            # Production settings
├── scripts/                    # Deployment scripts
│   ├── deploy-dev.sh          # Dev deployment
│   ├── deploy-prod.sh         # Prod deployment
│   └── destroy.sh             # Infrastructure cleanup
└── modules/                    # Future custom modules
```

## 🌍 Environment Configuration

### Development Environment
- **CIDR**: `10.0.0.0/16`
- **NAT Gateway**: Single (cost-optimized)
- **Flow Logs**: Disabled
- **Auto-shutdown**: Enabled

### Staging Environment
- **CIDR**: `10.1.0.0/16`
- **NAT Gateway**: Multiple (HA testing)
- **Flow Logs**: Enabled
- **Purpose**: Production-like testing

### Production Environment
- **CIDR**: `10.2.0.0/16`
- **NAT Gateway**: Multiple (high availability)
- **Flow Logs**: Enabled (required)
- **Monitoring**: Required

## 🚀 Deployment Guide

### Step 1: Environment Setup

Choose your target environment and review configuration:

```bash
# Review development configuration
cat environments/dev.tfvars

# Review production configuration
cat environments/prod.tfvars
```

### Step 2: Initialize Terraform

```bash
terraform init
```

### Step 3: Validate Configuration

```bash
terraform validate
terraform fmt -check
```

### Step 4: Plan Deployment

```bash
# Development
terraform plan -var-file="environments/dev.tfvars"

# Production
terraform plan -var-file="environments/prod.tfvars"
```

### Step 5: Deploy Infrastructure

#### Development Deployment
```bash
# Using script (recommended)
./scripts/deploy-dev.sh

# Or using Makefile
make deploy-dev

# Or manual
terraform apply -var-file="environments/dev.tfvars"
```

#### Production Deployment
```bash
# Using script (recommended - includes safety checks)
./scripts/deploy-prod.sh

# Or using Makefile
make deploy-prod
```

### Step 6: Verify Deployment

```bash
# Check outputs
terraform output

# Verify VPC in AWS Console
aws ec2 describe-vpcs --filters "Name=tag:Environment,Values=dev"
```

## 🗄️ Remote State Setup

### Step 1: Create S3 Bucket and DynamoDB Table

```bash
# Set variables
BUCKET_NAME="your-terraform-state-bucket"
REGION="us-east-1"
TABLE_NAME="terraform-state-lock"

# Create S3 bucket
aws s3 mb s3://$BUCKET_NAME --region $REGION

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table
aws dynamodb create-table \
  --table-name $TABLE_NAME \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region $REGION
```

### Step 2: Configure Backend

```bash
# Copy backend template
cp backend.tf.example backend.tf

# Edit backend.tf with your bucket details
```

```hcl
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

### Step 3: Initialize with Remote Backend

```bash
terraform init
```

## ⚙️ Configuration Reference

### Core Variables

| Variable | Description | Default | Environment |
|----------|-------------|---------|-------------|
| `aws_region` | AWS region | `us-east-1` | All |
| `environment` | Environment name | `dev` | All |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` | Dev |
| `single_nat_gateway` | Use single NAT | `true` | Dev |
| `enable_flow_log` | Enable VPC Flow Logs | `false` | Dev |

### Environment-Specific Defaults

#### Development
```hcl
single_nat_gateway = true   # Cost optimization
enable_flow_log = false     # Optional
```

#### Staging
```hcl
single_nat_gateway = false  # Test HA setup
enable_flow_log = true      # Test monitoring
```

#### Production
```hcl
single_nat_gateway = false  # High availability
enable_flow_log = true      # Required
```

## 📤 Outputs

After deployment, access these outputs:

```bash
# View all outputs
terraform output

# Specific outputs
terraform output vpc_id
terraform output public_subnets
terraform output private_subnets
terraform output database_subnets
terraform output nat_public_ips
```

### Key Outputs
- `vpc_id`: VPC identifier for other resources
- `public_subnets`: For load balancers, bastion hosts
- `private_subnets`: For application servers
- `database_subnets`: For RDS, ElastiCache
- `database_subnet_group`: For RDS deployment

## 🔧 Management Commands

### Using Makefile
```bash
# View available commands
make help

# Plan deployments
make plan-dev
make plan-prod

# Deploy environments
make deploy-dev
make deploy-prod

# Destroy environments
make destroy-dev
make destroy-prod

# Maintenance
make validate
make format
make clean
```

### Using Scripts
```bash
# Deploy environments
./scripts/deploy-dev.sh
./scripts/deploy-prod.sh

# Destroy environments
./scripts/destroy.sh dev
./scripts/destroy.sh prod
```

## 📋 Best Practices

### Security
- Database subnets have no internet access
- VPC Flow Logs enabled in staging/production
- Comprehensive resource tagging
- S3 bucket encryption enabled

### Cost Optimization
- Development uses single NAT Gateway
- Environment-specific resource sizing
- Proper resource tagging for cost allocation

### High Availability
- Multi-AZ deployment
- Production uses multiple NAT Gateways
- Database subnet groups span AZs

### Operations
- Environment-specific configurations
- Automated deployment scripts
- Remote state management
- Comprehensive outputs

## 🔍 Troubleshooting

### Common Issues

#### 1. Insufficient Permissions
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify permissions
aws iam simulate-principal-policy \
  --policy-source-arn $(aws sts get-caller-identity --query Arn --output text) \
  --action-names ec2:CreateVpc \
  --resource-arns "*"
```

#### 2. CIDR Conflicts
```bash
# Check existing VPCs
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock]' --output table
```

#### 3. Availability Zone Issues
```bash
# List available AZs
aws ec2 describe-availability-zones --query 'AvailabilityZones[*].ZoneName'
```

#### 4. State Lock Issues
```bash
# Force unlock (use carefully)
terraform force-unlock <lock-id>
```

### Validation Commands
```bash
# Validate configuration
terraform validate

# Check formatting
terraform fmt -check -diff

# Plan without applying
terraform plan -detailed-exitcode
```

### Cleanup Commands
```bash
# Clean temporary files
make clean

# Or manually
rm -f tfplan-* destroy-plan-* terraform.tfplan
```

## 📞 Support

For issues and questions:
1. Check this troubleshooting section
2. Review [AWS VPC module documentation](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
3. Open an issue in the repository

## 📄 License

This project is licensed under the MIT License.
