# Three-Tier VPC Terraform Makefile

.PHONY: help init validate format plan-dev plan-staging plan-prod deploy-dev deploy-staging deploy-prod destroy-dev destroy-staging destroy-prod clean

# Default target
help:
	@echo "Available commands:"
	@echo "  init           - Initialize Terraform"
	@echo "  validate       - Validate Terraform configuration"
	@echo "  format         - Format Terraform files"
	@echo "  plan-dev       - Plan development deployment"
	@echo "  plan-staging   - Plan staging deployment"
	@echo "  plan-prod      - Plan production deployment"
	@echo "  deploy-dev     - Deploy development environment"
	@echo "  deploy-staging - Deploy staging environment"
	@echo "  deploy-prod    - Deploy production environment"
	@echo "  destroy-dev    - Destroy development environment"
	@echo "  destroy-staging- Destroy staging environment"
	@echo "  destroy-prod   - Destroy production environment"
	@echo "  clean          - Clean temporary files"

# Initialize Terraform
init:
	terraform init

# Validate configuration
validate:
	terraform validate

# Format Terraform files
format:
	terraform fmt -recursive

# Plan deployments
plan-dev:
	terraform plan -var-file="environments/dev.tfvars"

plan-staging:
	terraform plan -var-file="environments/staging.tfvars"

plan-prod:
	terraform plan -var-file="environments/prod.tfvars"

# Deploy environments
deploy-dev:
	./scripts/deploy-dev.sh

deploy-staging:
	terraform apply -var-file="environments/staging.tfvars"

deploy-prod:
	./scripts/deploy-prod.sh

# Destroy environments
destroy-dev:
	./scripts/destroy.sh dev

destroy-staging:
	./scripts/destroy.sh staging

destroy-prod:
	./scripts/destroy.sh prod

# Clean temporary files
clean:
	rm -f tfplan-* destroy-plan-* terraform.tfplan
	rm -rf .terraform/
