# Terraform + GitHub Actions with OIDC Authentication

## Architecture Overview

This project deploys a production-grade VPC infrastructure on AWS using Terraform with GitHub Actions CI/CD pipeline. The setup uses OIDC authentication for secure, keyless AWS access.

**Infrastructure Components:**
- VPC with public/private subnets across 2 AZs
- NAT Gateway for private subnet internet access
- DNS hostnames and resolution enabled
- Remote state management with S3 + DynamoDB locking

## Project Structure

```
github-action/
├── README.md
├── modules/
│   └── vpc/
│       ├── main.tf          # VPC module implementation
│       ├── variables.tf     # Module input variables
│       └── outputs.tf       # Module outputs
├── envs/
│   └── prod/
│       ├── backend.tf       # S3 backend configuration
│       ├── main.tf          # Main infrastructure code
│       ├── providers.tf     # AWS provider configuration
│       ├── variables.tf     # Environment variables
│       └── terraform.tfvars # Production values
└── .github/
    └── workflows/
        └── terraform.yaml   # CI/CD pipeline
```

## Prerequisites Setup

### 1. Create S3 Bucket for Terraform State

```bash
aws s3 mb s3://your-terraform-state-bucket-name --region ap-south-1
aws s3api put-bucket-versioning --bucket your-terraform-state-bucket-name --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket  --server-side-encryption-configuration '{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }
  ]
}'
```


### 2. Create DynamoDB Table for State Locking

```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region ap-south-1
```

### 3. Create IAM OIDC Role for GitHub Actions

```bash
# Create trust policy
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:*"
        }
      }
    }
  ]
}
EOF


Example
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::141745357479:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:*"
        }
      }
    }
  ]
}
EOF






# Create the role
aws iam create-role \
  --role-name GitHubActionsRole \
  --assume-role-policy-document file://trust-policy.json

# Attach necessary policies
aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# Create OIDC provider (if not exists)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --client-id-list sts.amazonaws.com
```

### 4. GitHub Repository Secrets

Add these secrets to your GitHub repository:
- `AWS_ROLE_ARN`: `arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsRole`
- `AWS_REGION`: `ap-south-1`

## GitHub Actions Pipeline

The CI/CD pipeline automatically:

**On Pull Requests:**
- Runs `terraform fmt -check`
- Runs `terraform validate`
- Runs `terraform plan`
- Posts plan output as PR comment

**On Push to Main:**
- Runs all PR checks
- Automatically applies changes with `terraform apply`

## Local Development

### Initialize Terraform

```bash
cd github-action/envs/prod
terraform init
```

### Plan Changes

```bash
terraform plan
```

### Apply Changes

```bash
terraform apply
```

### Format Code

```bash
terraform fmt -recursive
```

## CI/CD Flow

1. **Feature Development**: Create feature branch, make changes
2. **Pull Request**: Opens PR → triggers plan-only workflow
3. **Code Review**: Review Terraform plan output in PR comments
4. **Merge**: Merge to main → triggers full deployment workflow
5. **Deployment**: Automatic `terraform apply` on main branch

## Security Features

- OIDC authentication (no long-lived access keys)
- Encrypted S3 state storage
- DynamoDB state locking
- Least privilege IAM policies
- Terraform state versioning enabled

## Monitoring

Monitor deployments through:
- GitHub Actions workflow logs
- AWS CloudTrail for API calls
- Terraform state file versions in S3
