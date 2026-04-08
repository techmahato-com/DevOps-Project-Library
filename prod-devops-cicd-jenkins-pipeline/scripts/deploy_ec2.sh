#!/bin/bash
# =============================================================================
# Deploy application to EC2 via SSM Run Command
# Usage: ./deploy_ec2.sh <instance-id> <ecr-image-uri> <aws-region>
# =============================================================================
set -euo pipefail

INSTANCE_ID="${1:?Usage: $0 <instance-id> <ecr-image-uri> <aws-region>}"
IMAGE_URI="${2:?Usage: $0 <instance-id> <ecr-image-uri> <aws-region>}"
AWS_REGION="${3:-us-east-1}"
CONTAINER_NAME="app"
APP_PORT="${APP_PORT:-8080}"

echo "Deploying ${IMAGE_URI} to ${INSTANCE_ID}..."

COMMAND=$(cat << EOF
#!/bin/bash
set -e
REGION="${AWS_REGION}"
IMAGE="${IMAGE_URI}"

# Authenticate Docker to ECR
aws ecr get-login-password --region "\$REGION" | \
  docker login --username AWS --password-stdin "\$(echo \$IMAGE | cut -d/ -f1)"

# Pull latest image
docker pull "\$IMAGE"

# Stop and remove existing container if running
docker stop "${CONTAINER_NAME}" 2>/dev/null || true
docker rm   "${CONTAINER_NAME}" 2>/dev/null || true

# Run new container
docker run -d \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  -p "${APP_PORT}:${APP_PORT}" \
  "\$IMAGE"

echo "Deployment complete. Container status:"
docker ps --filter "name=${CONTAINER_NAME}"
EOF
)

# Send command via SSM (no SSH required)
COMMAND_ID=$(aws ssm send-command \
  --region "$AWS_REGION" \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters "commands=[\"$COMMAND\"]" \
  --query "Command.CommandId" \
  --output text)

echo "SSM Command ID: ${COMMAND_ID}"
echo "Waiting for command to complete..."

aws ssm wait command-executed \
  --region "$AWS_REGION" \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID"

aws ssm get-command-invocation \
  --region "$AWS_REGION" \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query "{Status:Status,Output:StandardOutputContent}" \
  --output table
