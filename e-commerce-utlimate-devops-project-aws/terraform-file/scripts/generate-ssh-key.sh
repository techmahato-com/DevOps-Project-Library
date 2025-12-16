#!/bin/bash

# SSH Key Generation Script for Bastion Host
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

# Default values
KEY_NAME="bastion-key"
KEY_DIR="$HOME/.ssh"
ENV="dev"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --key-name)
            KEY_NAME="$2"
            shift 2
            ;;
        --key-dir)
            KEY_DIR="$2"
            shift 2
            ;;
        --env)
            ENV="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --key-name    Name of the SSH key (default: bastion-key)"
            echo "  --key-dir     Directory to store keys (default: ~/.ssh)"
            echo "  --env         Environment (default: dev)"
            echo "  --help        Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Create SSH directory if it doesn't exist
mkdir -p "$KEY_DIR"

# Full paths
PRIVATE_KEY="$KEY_DIR/${KEY_NAME}"
PUBLIC_KEY="$KEY_DIR/${KEY_NAME}.pub"

print_status "🔑 Generating SSH key pair for bastion host..."

# Check if key already exists
if [[ -f "$PRIVATE_KEY" ]]; then
    print_warning "SSH key already exists at $PRIVATE_KEY"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Key generation cancelled"
        exit 1
    fi
fi

# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY" -N "" -C "bastion-host-${ENV}"

# Set proper permissions
chmod 600 "$PRIVATE_KEY"
chmod 644 "$PUBLIC_KEY"

print_success "SSH key pair generated successfully!"
print_status "Private key: $PRIVATE_KEY"
print_status "Public key: $PUBLIC_KEY"

# Read public key content
PUBLIC_KEY_CONTENT=$(cat "$PUBLIC_KEY")

print_status ""
print_status "📋 Next steps:"
print_status "1. Copy the public key content below:"
print_status ""
echo "$PUBLIC_KEY_CONTENT"
print_status ""
print_status "2. Update your tfvars file:"
print_status "   bastion_public_key = \"$PUBLIC_KEY_CONTENT\""
print_status ""
print_status "3. Deploy the infrastructure:"
print_status "   ./scripts/deploy.sh $ENV"
print_status ""
print_status "4. Connect to bastion host after deployment:"
print_status "   ssh -i $PRIVATE_KEY ubuntu@<bastion-public-ip>"
