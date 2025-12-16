#!/bin/bash

# Setup Script for Three-Tier VPC Project
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_status "🚀 Setting up Three-Tier VPC Project..."

# Check prerequisites
print_status "🔍 Checking prerequisites..."

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed"
    print_status "Please install Terraform: https://www.terraform.io/downloads.html"
    exit 1
fi

TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
print_success "Terraform $TERRAFORM_VERSION found"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed"
    print_status "Please install AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi

AWS_CLI_VERSION=$(aws --version | cut -d/ -f2 | cut -d' ' -f1)
print_success "AWS CLI $AWS_CLI_VERSION found"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    print_warning "jq is not installed (optional but recommended)"
    print_status "Install jq for better script output: sudo apt-get install jq"
fi

# Check AWS credentials
print_status "🔐 Checking AWS credentials..."
if aws sts get-caller-identity &>/dev/null; then
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    AWS_USER=$(aws sts get-caller-identity --query Arn --output text)
    print_success "AWS credentials configured"
    print_status "Account: $AWS_ACCOUNT"
    print_status "User: $AWS_USER"
else
    print_error "AWS credentials not configured"
    print_status "Please run: aws configure"
    exit 1
fi

# Create terraform.tfvars from example if it doesn't exist
if [ ! -f "terraform.tfvars" ]; then
    print_status "📝 Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    print_success "terraform.tfvars created"
    print_warning "Please review and update terraform.tfvars with your specific values"
fi

# Create backend.tf from example if it doesn't exist
if [ ! -f "backend.tf" ]; then
    print_status "📝 Creating backend.tf from example..."
    cp backend.tf.example backend.tf
    print_success "backend.tf created"
    print_warning "Please configure backend.tf for remote state management (recommended for production)"
fi

# Make scripts executable
print_status "🔧 Making scripts executable..."
chmod +x scripts/*.sh
print_success "Scripts are now executable"

# Initialize Terraform
print_status "📦 Initializing Terraform..."
if terraform init; then
    print_success "Terraform initialized successfully"
else
    print_error "Terraform initialization failed"
    exit 1
fi

# Validate configuration
print_status "✅ Validating Terraform configuration..."
if terraform validate; then
    print_success "Terraform configuration is valid"
else
    print_error "Terraform validation failed"
    exit 1
fi

# Format Terraform files
print_status "🎨 Formatting Terraform files..."
terraform fmt -recursive
print_success "Terraform files formatted"

print_success "🎉 Setup completed successfully!"
print_status ""
print_status "Next steps:"
print_status "1. Review and update terraform.tfvars with your specific values"
print_status "2. Configure backend.tf for remote state (recommended)"
print_status "3. Run: ./scripts/deploy.sh dev --plan-only"
print_status "4. Run: ./scripts/deploy.sh dev"
print_status ""
print_status "Available commands:"
print_status "  make help                    # Show all available make targets"
print_status "  ./scripts/deploy.sh --help   # Show deployment options"
print_status "  ./scripts/destroy.sh --help  # Show destroy options"
