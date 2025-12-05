#!/bin/bash

# Infrastructure Destroy Script
set -e

# Check if environment is provided
if [ $# -eq 0 ]; then
    echo "❌ Error: Environment not specified"
    echo "Usage: $0 <environment>"
    echo "Available environments: dev, staging, prod"
    exit 1
fi

ENV=$1
TFVARS_FILE="environments/${ENV}.tfvars"

# Check if tfvars file exists
if [ ! -f "$TFVARS_FILE" ]; then
    echo "❌ Error: $TFVARS_FILE not found"
    exit 1
fi

echo "🗑️  Destroying $ENV VPC Infrastructure..."

# Plan destroy
echo "📋 Planning destroy..."
terraform plan -destroy -var-file="$TFVARS_FILE" -out="destroy-plan-${ENV}"

# Show what will be destroyed
echo "📊 Resources to be destroyed:"
terraform show -json "destroy-plan-${ENV}" | jq -r '.resource_changes[] | select(.change.actions[] | contains("delete")) | .address'

# Confirmation based on environment
if [ "$ENV" = "prod" ]; then
    echo "⚠️  PRODUCTION DESTROY WARNING ⚠️"
    echo "This will DESTROY PRODUCTION infrastructure"
    read -p "🔐 Type 'DESTROY-PROD' to confirm: " confirmation
    
    if [ "$confirmation" != "DESTROY-PROD" ]; then
        echo "❌ Destroy cancelled - incorrect confirmation"
        rm -f "destroy-plan-${ENV}"
        exit 1
    fi
fi

read -p "🤔 Are you sure you want to destroy $ENV infrastructure? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "💥 Destroying infrastructure..."
    terraform apply "destroy-plan-${ENV}"
    echo "✅ $ENV infrastructure destroyed successfully!"
else
    echo "❌ Destroy cancelled"
fi

# Clean up plan file
rm -f "destroy-plan-${ENV}"
