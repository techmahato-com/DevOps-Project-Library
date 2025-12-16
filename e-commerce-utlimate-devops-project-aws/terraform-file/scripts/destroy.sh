#!/bin/bash

# Universal Destroy Script for Three-Tier VPC
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
    echo "  --plan-only     - Only run terraform plan -destroy"
    echo "  --help          - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 dev                    # Destroy development environment"
    echo "  $0 prod --plan-only       # Plan production destruction"
    echo "  $0 staging --auto-approve # Destroy staging without prompts"
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
DESTROY_PLAN_FILE="destroy-plan-${ENV}"

# Check if tfvars file exists
if [ ! -f "$TFVARS_FILE" ]; then
    print_error "$TFVARS_FILE not found"
    exit 1
fi

print_warning "🗑️  Destroying $ENV VPC Infrastructure..."

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

# Plan destroy
print_status "📋 Planning destroy..."
if ! terraform plan -destroy -var-file="$TFVARS_FILE" -out="$DESTROY_PLAN_FILE"; then
    print_error "Terraform destroy planning failed"
    exit 1
fi

# Show what will be destroyed
print_status "📊 Resources to be destroyed:"
RESOURCES_TO_DELETE=$(terraform show -json "$DESTROY_PLAN_FILE" 2>/dev/null | jq -r '.resource_changes[]? | select(.change.actions[]? | contains("delete")) | .address' | wc -l || echo "0")
echo "  Total resources to delete: $RESOURCES_TO_DELETE"

if [ "$RESOURCES_TO_DELETE" -gt 0 ]; then
    terraform show -json "$DESTROY_PLAN_FILE" 2>/dev/null | jq -r '.resource_changes[]? | select(.change.actions[]? | contains("delete")) | .address' | head -10
    if [ "$RESOURCES_TO_DELETE" -gt 10 ]; then
        echo "  ... and $((RESOURCES_TO_DELETE - 10)) more resources"
    fi
fi

# Exit if plan-only
if [ "$PLAN_ONLY" = true ]; then
    print_success "Destroy plan completed successfully!"
    rm -f "$DESTROY_PLAN_FILE"
    exit 0
fi

# Confirmation logic
if [ "$AUTO_APPROVE" = false ]; then
    if [ "$ENV" = "prod" ]; then
        print_error "⚠️  PRODUCTION DESTROY WARNING ⚠️"
        echo "This will DESTROY PRODUCTION infrastructure"
        echo "This action is IRREVERSIBLE!"
        read -p "🔐 Type 'DESTROY-PROD' to confirm: " confirmation
        
        if [ "$confirmation" != "DESTROY-PROD" ]; then
            print_error "Destroy cancelled - incorrect confirmation"
            rm -f "$DESTROY_PLAN_FILE"
            exit 1
        fi
    fi
    
    read -p "🤔 Are you sure you want to destroy $ENV infrastructure? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Destroy cancelled"
        rm -f "$DESTROY_PLAN_FILE"
        exit 1
    fi
fi

# Apply destroy
print_status "💥 Destroying infrastructure..."
if terraform apply "$DESTROY_PLAN_FILE"; then
    print_success "✅ $ENV infrastructure destroyed successfully!"
else
    print_error "Terraform destroy failed"
    rm -f "$DESTROY_PLAN_FILE"
    exit 1
fi

# Clean up plan file
rm -f "$DESTROY_PLAN_FILE"

print_success "🎉 $ENV infrastructure destruction completed!"
