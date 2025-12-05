#!/bin/bash

# Production Environment Deployment Script
set -e

echo "🚀 Deploying Production VPC Infrastructure..."

# Set environment
ENV="prod"
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

# Show plan summary
echo "📊 Plan Summary:"
terraform show -json "tfplan-${ENV}" | jq -r '.resource_changes[] | select(.change.actions[] | contains("create")) | .address' | wc -l | xargs echo "Resources to create:"

# Multiple confirmations for production
echo "⚠️  PRODUCTION DEPLOYMENT WARNING ⚠️"
echo "This will deploy infrastructure to PRODUCTION environment"
read -p "🔐 Type 'DEPLOY-PROD' to confirm: " confirmation

if [ "$confirmation" != "DEPLOY-PROD" ]; then
    echo "❌ Deployment cancelled - incorrect confirmation"
    rm -f "tfplan-${ENV}"
    exit 1
fi

read -p "🤔 Final confirmation - Deploy to PRODUCTION? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔨 Applying Terraform plan..."
    terraform apply "tfplan-${ENV}"
    echo "✅ Production VPC deployed successfully!"
else
    echo "❌ Deployment cancelled"
    rm -f "tfplan-${ENV}"
    exit 1
fi

# Clean up plan file
rm -f "tfplan-${ENV}"

echo "🎉 Production deployment completed!"
