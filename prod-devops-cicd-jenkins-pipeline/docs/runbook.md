# Runbook

## Prerequisites

- AWS CLI >= 2.x configured (`aws sts get-caller-identity` must succeed)
- Terraform >= 1.9.0 installed
- SSM Session Manager plugin installed locally

## Current Dev Environment

Already deployed. State is in S3. To work with it:

```bash
cd terraform/env/dev
terraform init        # connects to S3 backend automatically
terraform plan -var-file=terraform.tfvars   # should show: No changes
```

---

## Bootstrap (First Time / Fresh Account)

Only needed if starting from scratch. The S3 bucket and DynamoDB table
must exist before the remote backend can be enabled.

```bash
cd terraform/env/dev

# Step 1: Comment out the entire terraform { backend "s3" {} } block in backend.tf
# Step 2: Init and create only the state resources
terraform init
terraform apply -target=module.s3_backend -target=module.dynamodb_lock -var-file=terraform.tfvars

# Step 3: Uncomment backend.tf, update bucket/table names to match tfvars output
# Step 4: Migrate local state to S3
terraform init -migrate-state -force-copy

# Step 5: Deploy everything else
terraform apply -var-file=terraform.tfvars
```

Or use the automated bootstrap script:
```bash
./bootstrap.sh dev
```

---

## Access Jenkins (SSM Port Forwarding)

```bash
# Install SSM plugin first (Windows):
# https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows/SessionManagerPluginSetup.exe

aws ssm start-session \
  --target i-0dedbe4a946c00b00 \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["8080"],"localPortNumber":["8080"]}' \
  --region us-east-1

# Open: http://localhost:8080
# Initial admin password: 298de33470f849d3a228b87fe42d4f7f
```

## Access SonarQube (SSM Port Forwarding)

```bash
aws ssm start-session \
  --target i-0fa1ebdf2695dfb1b \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["9000"],"localPortNumber":["9000"]}' \
  --region us-east-1

# Open: http://localhost:9000
# Default credentials: admin / admin  (change on first login)
```

## Shell Access via SSM

```bash
# Jenkins instance
aws ssm start-session --target i-0dedbe4a946c00b00 --region us-east-1

# SonarQube instance
aws ssm start-session --target i-0fa1ebdf2695dfb1b --region us-east-1
```

---

## Re-run Bootstrap Script on Existing Instance

If software needs to be reinstalled (e.g. after AMI change):

```bash
# Upload script to S3
aws s3 cp jenkins/install_jenkins.sh \
  s3://myapp-dev-tfstate-441345502954/scripts/install_jenkins.sh

# Run via SSM
aws ssm send-command \
  --region us-east-1 \
  --instance-ids i-0dedbe4a946c00b00 \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=["aws s3 cp s3://myapp-dev-tfstate-441345502954/scripts/install_jenkins.sh /tmp/install_jenkins.sh --region us-east-1 && bash /tmp/install_jenkins.sh"]' \
  --timeout-seconds 900 \
  --query 'Command.CommandId' --output text
```

Check result:
```bash
aws ssm get-command-invocation \
  --region us-east-1 \
  --command-id <command-id> \
  --instance-id i-0dedbe4a946c00b00 \
  --query '[Status,StandardOutputContent]' --output text
```

---

## Enable Jenkins Agent

```bash
# In terraform/env/dev/terraform.tfvars:
create_jenkins_agent = true

terraform apply -var-file=terraform.tfvars
```

## Update AMI

```bash
# 1. Find latest AL2023 AMI
aws ec2 describe-images --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" \
  --query 'sort_by(Images,&CreationDate)[-1].ImageId' --output text

# 2. Update ami_id in terraform.tfvars
# 3. Taint the instance to force replacement with new AMI + fresh bootstrap
terraform taint 'module.jenkins.aws_instance.this[0]'
terraform apply -var-file=terraform.tfvars
```

## Destroy Dev Environment

```bash
cd terraform/env/dev

# Destroy all resources except the state bucket (prevent_destroy = true)
terraform destroy \
  -target=module.vpc \
  -target=module.security_groups \
  -target=module.ecr \
  -target=module.iam \
  -target=module.jenkins \
  -target=module.sonarqube \
  -target=module.jenkins_agent \
  -target=module.dynamodb_lock \
  -var-file=terraform.tfvars

# To also destroy the state bucket:
# 1. Remove prevent_destroy from terraform/modules/s3-backend/main.tf
# 2. Empty the bucket: aws s3 rm s3://myapp-dev-tfstate-441345502954 --recursive
# 3. terraform destroy -var-file=terraform.tfvars
```
