#!/bin/bash
# =============================================================================
# bootstrap.sh — One-time setup before running terraform apply
#
# What it does:
#   1. Validates prerequisites (terraform, aws, jq)
#   2. Auto-resolves latest AL2023 AMI + fck-nat AMI → patches terraform.tfvars
#   3. Creates S3 state bucket directly via AWS CLI (versioned, encrypted)
#   4. Writes backend.tf with real bucket name
#
# After this script completes, run manually:
#   cd terraform/env/dev
#   terraform init
#   terraform plan -var-file=terraform.tfvars
#   terraform apply -var-file=terraform.tfvars
#
# Usage: ./bootstrap.sh [dev]
# =============================================================================
set -euo pipefail

ENV="${1:-dev}"
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
ENV_DIR="$REPO_ROOT/terraform/env/$ENV"
TFVARS="$ENV_DIR/terraform.tfvars"
BACKEND="$ENV_DIR/backend.tf"

echo "=== Bootstrap: environment=$ENV ==="

# ─── 1. Prerequisites ─────────────────────────────────────────────────────────
for cmd in terraform aws jq; do
  command -v "$cmd" &>/dev/null || { echo "ERROR: '$cmd' not found"; exit 1; }
done
aws sts get-caller-identity --query 'Arn' --output text

# ─── 2. Read tfvars values ────────────────────────────────────────────────────
get_tfvar() { grep -E "^${1}\s*=" "$TFVARS" | sed 's/.*=\s*"\(.*\)"/\1/' | tr -d ' '; }

AWS_REGION=$(get_tfvar "aws_region")
PROJECT_NAME=$(get_tfvar "project_name")
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="${PROJECT_NAME}-${ENV}-tfstate-${ACCOUNT_ID}"

# ─── 3. Resolve latest AL2023 AMI ─────────────────────────────────────────────
echo "Resolving latest AL2023 AMI in $AWS_REGION..."
AL2023_AMI=$(aws ec2 describe-images \
  --region "$AWS_REGION" --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" \
  --query 'sort_by(Images,&CreationDate)[-1].ImageId' --output text)
echo "AL2023 AMI: $AL2023_AMI"

if grep -q 'ami_id\s*=\s*"ami-XXXXXXXXXXXXXXXXX"' "$TFVARS"; then
  sed -i "s|ami_id\s*=\s*\"ami-XXXXXXXXXXXXXXXXX\"|ami_id                   = \"$AL2023_AMI\"|" "$TFVARS"
  echo "Patched ami_id"
fi

# ─── 4. Resolve fck-nat AMI ───────────────────────────────────────────────────
if grep -q 'nat_instance_ami\s*=\s*"ami-XXXXXXXXXXXXXXXXX"' "$TFVARS"; then
  echo "Resolving latest fck-nat AMI..."
  FCKNAT_AMI=$(aws ec2 describe-images \
    --region "$AWS_REGION" --owners 568608671756 \
    --filters "Name=name,Values=fck-nat-al2023-*-x86_64-ebs" "Name=state,Values=available" \
    --query 'sort_by(Images,&CreationDate)[-1].ImageId' --output text 2>/dev/null || echo "")

  if [[ -n "$FCKNAT_AMI" && "$FCKNAT_AMI" != "None" ]]; then
    echo "fck-nat AMI: $FCKNAT_AMI"
    sed -i "s|nat_instance_ami\s*=\s*\"ami-XXXXXXXXXXXXXXXXX\".*|nat_instance_ami  = \"$FCKNAT_AMI\"|" "$TFVARS"
    echo "Patched nat_instance_ami"
  else
    echo "WARNING: Could not resolve fck-nat AMI — set nat_instance_ami manually"
  fi
fi

# ─── 5. Create S3 state bucket via AWS CLI ────────────────────────────────────
echo ""
echo "=== Creating S3 state bucket: $BUCKET_NAME ==="

if aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION" 2>/dev/null; then
  echo "Bucket already exists — skipping creation"
else
  if [[ "$AWS_REGION" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION"
  else
    aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION" \
      --create-bucket-configuration LocationConstraint="$AWS_REGION"
  fi

  # Enable versioning
  aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

  # Enable encryption
  aws s3api put-bucket-encryption --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms"},"BucketKeyEnabled":true}]}'

  # Block all public access
  aws s3api put-public-access-block --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
    'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'

  echo "Bucket created and configured"
fi

# ─── 6. Write backend.tf ──────────────────────────────────────────────────────
echo ""
echo "=== Writing backend.tf ==="
cat > "$BACKEND" << EOF
terraform {
  backend "s3" {
    bucket  = "$BUCKET_NAME"
    key     = "$ENV/terraform.tfstate"
    region  = "$AWS_REGION"
    encrypt = true
  }
}
EOF

# Update scripts_bucket_name in tfvars
sed -i "s|scripts_bucket_name = \".*\"|scripts_bucket_name = \"$BUCKET_NAME\"|" "$TFVARS"

echo ""
echo "=== Bootstrap complete ==="
echo "S3 bucket : $BUCKET_NAME"
echo "AMI       : $AL2023_AMI"
echo ""
echo "Next steps:"
echo "  cd terraform/env/$ENV"
echo "  terraform init"
echo "  terraform plan -var-file=terraform.tfvars"
echo "  terraform apply -var-file=terraform.tfvars"
