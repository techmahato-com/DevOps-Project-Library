# Three-Tier VPC Terraform Makefile

.PHONY: help setup init validate format plan-dev plan-staging plan-prod deploy-dev deploy-staging deploy-prod destroy-dev destroy-staging destroy-prod clean

# Default target
help:
	@echo "🚀 Three-Tier VPC Infrastructure Management"
	@echo ""
	@echo "Setup Commands:"
	@echo "  setup          - Initial project setup and validation"
	@echo "  init           - Initialize Terraform"
	@echo "  validate       - Validate Terraform configuration"
	@echo "  format         - Format Terraform files"
	@echo ""
	@echo "Planning Commands:"
	@echo "  plan-dev       - Plan development deployment"
	@echo "  plan-staging   - Plan staging deployment"
	@echo "  plan-prod      - Plan production deployment"
	@echo ""
	@echo "Deployment Commands:"
	@echo "  deploy-dev     - Deploy development environment"
	@echo "  deploy-staging - Deploy staging environment"
	@echo "  deploy-prod    - Deploy production environment"
	@echo ""
	@echo "Destroy Commands:"
	@echo "  destroy-dev    - Destroy development environment"
	@echo "  destroy-staging- Destroy staging environment"
	@echo "  destroy-prod   - Destroy production environment"
	@echo ""
	@echo "Utility Commands:"
	@echo "  clean          - Clean temporary files"
	@echo "  outputs        - Show Terraform outputs"
	@echo ""
	@echo "Examples:"
	@echo "  make setup && make deploy-dev    # Initial setup and dev deployment"
	@echo "  make plan-prod                   # Plan production deployment"

# Setup project
setup:
	@./scripts/setup.sh

# Initialize Terraform
init:
	@terraform init

# Validate configuration
validate:
	@terraform validate

# Format Terraform files
format:
	@terraform fmt -recursive

# Plan deployments
plan-dev:
	@./scripts/deploy.sh dev --plan-only

plan-staging:
	@./scripts/deploy.sh staging --plan-only

plan-prod:
	@./scripts/deploy.sh prod --plan-only

# Deploy environments
deploy-dev:
	@./scripts/deploy.sh dev

deploy-staging:
	@./scripts/deploy.sh staging

deploy-prod:
	@./scripts/deploy.sh prod

# Destroy environments
destroy-dev:
	@./scripts/destroy.sh dev

destroy-staging:
	@./scripts/destroy.sh staging

destroy-prod:
	@./scripts/destroy.sh prod

# Show outputs
outputs:
	@terraform output

# Clean temporary files
clean:
	@echo "🧹 Cleaning temporary files..."
	@rm -f tfplan-* destroy-plan-* terraform.tfplan
	@rm -rf .terraform/modules/
	@echo "✅ Cleanup completed"
