# Architecture

## Overview

Production-grade CI/CD pipeline platform on AWS for a Java/Maven application.
All infrastructure is provisioned and managed exclusively by Terraform.

## Deployed Environment: Dev

| Resource | Value |
|---|---|
| AWS Account | `441345502954` |
| Region | `us-east-1` |
| VPC CIDR | `10.0.0.0/16` |
| Jenkins EC2 | `i-0dedbe4a946c00b00` — `10.0.11.168` (t3.medium) |
| SonarQube EC2 | `i-0fa1ebdf2695dfb1b` — `10.0.12.24` (t3.medium) |
| NAT Instance | `i-06d55579fbb58912d` — `10.0.1.254` (t3.micro) |
| ECR Repository | `myapp-dev-app` |
| State Bucket | `myapp-dev-tfstate-441345502954` |
| Lock Table | `myapp-dev-tf-lock` |
| Terraform State | 51 resources, zero drift |

## High-Level Diagram

```
Internet
    │
    ▼
[Internet Gateway — igw-0b38bf3cd4b96e7bb]
    │
    ├── Public Subnet AZ-1 (10.0.1.0/24) ── [NAT Instance t3.micro]
    └── Public Subnet AZ-2 (10.0.2.0/24)

Private Subnet AZ-1 (10.0.11.0/24):
    └── Jenkins Controller EC2  (port 8080, 50000)

Private Subnet AZ-2 (10.0.12.0/24):
    └── SonarQube EC2           (port 9000, Docker container)

Supporting Services:
    ├── ECR          myapp-dev-app  (scan-on-push, lifecycle policy)
    ├── S3           myapp-dev-tfstate-441345502954  (KMS encrypted, versioned)
    ├── DynamoDB     myapp-dev-tf-lock  (state locking, PAY_PER_REQUEST)
    └── IAM          Jenkins + SonarQube instance profiles (least-privilege)

Future:
    └── Internal ALB  (module placeholder — not yet active)
```

## Terraform Module Structure

```
terraform/
  env/dev/              ← dev environment (only environment — no prod yet)
    main.tf             ← wires all modules
    variables.tf
    terraform.tfvars    ← actual deployed values
    backend.tf          ← S3 remote state
  modules/
    vpc/                ← VPC, subnets, IGW, NAT (gateway or instance)
    ec2/                ← Generic EC2, gp3 EBS, IMDSv2, no public IP
    security-group/     ← Jenkins, SonarQube, agent, ALB SGs
    iam/                ← Jenkins + SonarQube roles, instance profiles
    ecr/                ← ECR repos, scan-on-push, lifecycle policy
    s3-backend/         ← Terraform state bucket
    dynamodb-lock/      ← Terraform state lock table
    alb/                ← Internal ALB placeholder (future)
```

## Security Design

- All EC2 instances in private subnets — no public IPs
- Jenkins UI (8080) and SonarQube UI (9000) accessible only from `admin_cidr`
- Jenkins JNLP (50000) accessible from VPC CIDR only
- IMDSv2 enforced on all instances (`http_tokens = required`)
- EBS volumes encrypted at rest (gp3)
- S3 state bucket: KMS encrypted, versioned, public access blocked
- IAM roles use instance profiles — no static access keys anywhere
- ECR images scanned on push
- Security groups use `aws_vpc_security_group_ingress_rule` (AWS provider 5.x)

## NAT Mode

| Mode | Monthly Cost | Reliability | Current |
|---|---|---|---|
| `instance` (t3.micro) | ~$5/mo | Single point of failure | ✅ Dev |
| `gateway` | ~$32/mo + data | Managed, HA | Future prod |

Switch via `nat_mode` in `terraform.tfvars`.

## Installed Software (via user_data bootstrap)

### Jenkins (`10.0.11.168`)
| Tool | Version |
|---|---|
| Java (Corretto) | 17.0.18 |
| Jenkins LTS | 2.541.3 |
| Docker | 25.0.14 |
| Maven | 3.9.6 |
| Trivy | 0.69.3 |
| OWASP Dependency Check | 10.0.2 |

### SonarQube (`10.0.12.24`)
| Tool | Version |
|---|---|
| Docker | 25.0.14 |
| SonarQube | LTS Community (Docker container, up 15+ hours) |
