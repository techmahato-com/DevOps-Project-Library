#!/bin/bash

# Cleanup script for failed EKS deployment
set -e

ENVIRONMENT=${1:-dev}
TFVARS_FILE="environments/${ENVIRONMENT}.tfvars"

echo "🧹 Cleaning up failed EKS deployment for ${ENVIRONMENT} environment..."

# Remove failed addons from state
echo "📋 Removing failed addons from Terraform state..."
terraform state rm 'module.eks[0].aws_eks_addon.coredns' 2>/dev/null || true
terraform state rm 'module.eks[0].aws_eks_addon.ebs_csi_driver' 2>/dev/null || true
terraform state rm 'module.eks[0].aws_eks_addon.efs_csi_driver' 2>/dev/null || true
terraform state rm 'module.eks[0].aws_eks_addon.aws_load_balancer_controller' 2>/dev/null || true

echo "✅ Cleanup completed. You can now run terraform apply again."
echo "💡 Run: ./scripts/deploy.sh ${ENVIRONMENT}"
