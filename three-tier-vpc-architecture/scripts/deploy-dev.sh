#!/bin/bash

# Development Environment Deployment Script
set -e

echo "🚀 Deploying Development VPC Infrastructure..."

# Set environment
ENV="dev"
TFVARS_FILE="environments/${ENV}.tfvars"

# Check if tfvars file exists
if [ ! -f "$TFVARS_FILE" ]; then
    echo "❌ Error: $TFVARS_FILE not found"
    exit 1
fi

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init

# Validate configuration
echo "✅ Validating Terraform configuration..."
terraform validate

# Format check
echo "🎨 Checking Terraform formatting..."
terraform fmt -check

# Plan deployment
echo "📋 Planning deployment..."
terraform plan -var-file="$TFVARS_FILE" -out="tfplan-${ENV}"

# Ask for confirmation
read -p "🤔 Do you want to apply this plan? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔨 Applying Terraform plan..."
    terraform apply "tfplan-${ENV}"
    echo "✅ Development VPC deployed successfully!"
else
    echo "❌ Deployment cancelled"
    rm -f "tfplan-${ENV}"
    exit 1
fi

# Clean up plan file
rm -f "tfplan-${ENV}"

echo "🎉 Development deployment completed!"
