# prod-devops-cicd-jenkins-pipeline

Production-grade CI/CD pipeline platform for a Java/Maven application on AWS, provisioned with Terraform.

## Stack

| Layer | Technology |
|---|---|
| Infrastructure | Terraform >= 1.9, AWS Provider ~> 5.0 |
| CI/CD | Jenkins LTS (EC2, private subnet) |
| Code Quality | SonarQube LTS (EC2, private subnet) |
| Security Scanning | OWASP Dependency Check, Trivy |
| Container Registry | Amazon ECR |
| Build Tool | Maven 3.9 |
| Runtime | Docker, Amazon Linux 2023 |
| State Backend | S3 + DynamoDB |

## Repository Structure

```
├── app/                    Java/Maven application source + Jenkinsfile + Dockerfile
├── terraform/
│   ├── modules/            Reusable Terraform modules
│   │   ├── vpc/            VPC, subnets, IGW, NAT (gateway or instance)
│   │   ├── ec2/            Generic EC2 with gp3 EBS, IMDSv2, no public IP
│   │   ├── security-group/ Jenkins, SonarQube, agent, ALB security groups
│   │   ├── iam/            Jenkins and SonarQube IAM roles + instance profiles
│   │   ├── ecr/            ECR repositories with scan-on-push + lifecycle policy
│   │   ├── s3-backend/     Terraform state S3 bucket (encrypted, versioned)
│   │   ├── dynamodb-lock/  Terraform state lock table (PAY_PER_REQUEST)
│   │   └── alb/            Internal ALB placeholder (future use)
│   └── env/
│       ├── dev/            Dev environment (NAT instance, t3.medium, cost-optimized)
│       └── prod/           Prod environment (NAT Gateway, t3.large, IMMUTABLE ECR tags)
├── jenkins/
│   ├── install_jenkins.sh  Bootstrap: Java 17, Jenkins, Docker, Maven, Trivy, OWASP DC
│   ├── install_tools.sh    Standalone tool installer (idempotent)
│   └── plugins.txt         Jenkins plugin list
├── sonar/
│   ├── docker-compose.yml  SonarQube via Docker Compose
│   └── sonar-install.sh    Bootstrap script for SonarQube EC2
├── scripts/                Utility scripts (deploy, health check, tool installs)
└── docs/                   Architecture, runbook, pipeline flow, troubleshooting
```

## Quick Start

### 1. Prerequisites

```bash
# Verify tools
terraform version   # >= 1.10.0
aws --version       # >= 2.x
```

Configure AWS credentials:
```bash
aws configure
# or use an IAM role if running from EC2/CI
```

### 2. Update Variables

Edit `terraform/env/dev/terraform.tfvars`:
- Set `ami_id` to the latest Amazon Linux 2023 AMI for your region
- Set `nat_instance_ami` if using `nat_mode = "instance"`
- Set `admin_cidr` to your VPN/bastion CIDR
- Set `bucket_suffix` to your AWS account ID or a unique string

```bash
# Find latest AL2023 AMI
aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" \
  --query 'sort_by(Images,&CreationDate)[-1].ImageId' \
  --output text
```

### 3. Bootstrap Remote State

```bash
cd terraform/env/dev

# Comment out backend.tf content first, then:
terraform init
terraform apply -target=module.s3_backend -target=module.dynamodb_lock

# Uncomment backend.tf, update values, then:
terraform init -migrate-state
```

### 4. Deploy Dev

```bash
cd terraform/env/dev
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

### 5. Deploy Prod

```bash
cd terraform/env/prod
# Update terraform.tfvars with prod values
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Module Usage

Each module is self-contained with `variables.tf`, `main.tf`, and `outputs.tf`.

```hcl
module "vpc" {
  source               = "../../modules/vpc"
  project_name         = "myapp"
  environment          = "dev"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b"]
  nat_mode             = "instance"
  nat_instance_ami     = "ami-xxxxxxxxx"
}
```

## Security Assumptions

- No EC2 instance has a public IP address
- Jenkins and SonarQube are accessible only from `admin_cidr` (your VPN/bastion)
- All EBS volumes are encrypted (gp3)
- IMDSv2 is enforced on all instances
- IAM roles use instance profiles — no static access keys in code
- S3 state bucket has public access blocked and KMS encryption enabled
- ECR images are scanned on push

## Cost Notes

| Resource | Dev (est.) | Prod (est.) |
|---|---|---|
| Jenkins EC2 (t3.medium) | ~$30/mo | — |
| Jenkins EC2 (t3.large) | — | ~$60/mo |
| SonarQube EC2 (t3.medium) | ~$30/mo | — |
| SonarQube EC2 (t3.large) | — | ~$60/mo |
| NAT Instance (t3.micro) | ~$8/mo | — |
| NAT Gateway | — | ~$32/mo + data |
| ECR | ~$0.10/GB/mo | ~$0.10/GB/mo |
| S3 + DynamoDB | < $1/mo | < $1/mo |

Switch `nat_mode = "instance"` in dev to save ~$24/month vs NAT Gateway.

## Further Reading

- [Architecture](docs/architecture.md)
- [Pipeline Flow](docs/pipeline-flow.md)
- [Runbook](docs/runbook.md)
- [Troubleshooting](docs/troubleshooting.md)
