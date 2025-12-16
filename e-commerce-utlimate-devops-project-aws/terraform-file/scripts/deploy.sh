#!/bin/bash

# Universal Deployment Script for Three-Tier VPC
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <environment> [options]"
    echo ""
    echo "Environments:"
    echo "  dev      - Development environment"
    echo "  staging  - Staging environment"
    echo "  prod     - Production environment"
    echo ""
    echo "Options:"
    echo "  --auto-approve  - Skip confirmation prompts"
    echo "  --plan-only     - Only run terraform plan"
    echo "  --help          - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 dev                    # Deploy development environment"
    echo "  $0 prod --plan-only       # Plan production deployment"
    echo "  $0 staging --auto-approve # Deploy staging without prompts"
}

# Parse arguments
ENV=""
AUTO_APPROVE=false
PLAN_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        dev|staging|prod)
            ENV="$1"
            shift
            ;;
        --auto-approve)
            AUTO_APPROVE=true
            shift
            ;;
        --plan-only)
            PLAN_ONLY=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate environment
if [ -z "$ENV" ]; then
    print_error "Environment not specified"
    show_usage
    exit 1
fi

# Set variables
TFVARS_FILE="environments/${ENV}.tfvars"
PLAN_FILE="tfplan-${ENV}"

# Check if tfvars file exists
if [ ! -f "$TFVARS_FILE" ]; then
    print_error "$TFVARS_FILE not found"
    exit 1
fi

print_status "🚀 Deploying $ENV VPC Infrastructure..."

# Check AWS credentials
if ! aws sts get-caller-identity &>/dev/null; then
    print_error "AWS credentials not configured or invalid"
    print_status "Please run: aws configure"
    exit 1
fi

# Initialize Terraform
print_status "📦 Initializing Terraform..."
if ! terraform init; then
    print_error "Terraform initialization failed"
    exit 1
fi

# Validate configuration
print_status "✅ Validating Terraform configuration..."
if ! terraform validate; then
    print_error "Terraform validation failed"
    exit 1
fi

# Format check
print_status "🎨 Checking Terraform formatting..."
if ! terraform fmt -check -recursive; then
    print_warning "Terraform files are not properly formatted"
    print_status "Running terraform fmt to fix formatting..."
    terraform fmt -recursive
fi

# Plan deployment
print_status "📋 Planning deployment..."
if ! terraform plan -var-file="$TFVARS_FILE" -out="$PLAN_FILE"; then
    print_error "Terraform planning failed"
    exit 1
fi

# Show plan summary
print_status "📊 Plan Summary:"
RESOURCES_TO_CREATE=$(terraform show -json "$PLAN_FILE" 2>/dev/null | jq -r '.resource_changes[]? | select(.change.actions[]? | contains("create")) | .address' | wc -l || echo "0")
RESOURCES_TO_MODIFY=$(terraform show -json "$PLAN_FILE" 2>/dev/null | jq -r '.resource_changes[]? | select(.change.actions[]? | contains("update")) | .address' | wc -l || echo "0")
RESOURCES_TO_DELETE=$(terraform show -json "$PLAN_FILE" 2>/dev/null | jq -r '.resource_changes[]? | select(.change.actions[]? | contains("delete")) | .address' | wc -l || echo "0")

echo "  Resources to create: $RESOURCES_TO_CREATE"
echo "  Resources to modify: $RESOURCES_TO_MODIFY"
echo "  Resources to delete: $RESOURCES_TO_DELETE"

# Exit if plan-only
if [ "$PLAN_ONLY" = true ]; then
    print_success "Plan completed successfully!"
    rm -f "$PLAN_FILE"
    exit 0
fi

# Confirmation logic
if [ "$AUTO_APPROVE" = false ]; then
    if [ "$ENV" = "prod" ]; then
        print_warning "⚠️  PRODUCTION DEPLOYMENT WARNING ⚠️"
        echo "This will deploy infrastructure to PRODUCTION environment"
        read -p "🔐 Type 'DEPLOY-PROD' to confirm: " confirmation
        
        if [ "$confirmation" != "DEPLOY-PROD" ]; then
            print_error "Deployment cancelled - incorrect confirmation"
            rm -f "$PLAN_FILE"
            exit 1
        fi
    fi
    
    read -p "🤔 Do you want to apply this plan? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Deployment cancelled"
        rm -f "$PLAN_FILE"
        exit 1
    fi
fi

# Apply deployment
print_status "🔨 Applying Terraform plan..."
if terraform apply "$PLAN_FILE"; then
    print_success "✅ $ENV VPC deployed successfully!"
else
    print_error "Terraform apply failed"
    rm -f "$PLAN_FILE"
    exit 1
fi

# Clean up plan file
rm -f "$PLAN_FILE"

print_success "🎉 $ENV deployment completed!"

# Show outputs
print_status "📋 Infrastructure Outputs:"
terraform output
