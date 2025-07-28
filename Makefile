# Makefile for Automated Cloud Infrastructure

.PHONY: help init-backend init-dev init-prod plan-dev plan-prod apply-dev apply-prod destroy-dev destroy-prod validate format clean

# Default target
help:
	@echo "Available targets:"
	@echo "  init-backend  - Initialize Terraform backend (S3 + DynamoDB)"
	@echo "  init-dev      - Initialize development environment"
	@echo "  init-prod     - Initialize production environment"
	@echo "  plan-dev      - Plan development environment changes"
	@echo "  plan-prod     - Plan production environment changes"
	@echo "  apply-dev     - Apply development environment changes"
	@echo "  apply-prod    - Apply production environment changes"
	@echo "  destroy-dev   - Destroy development environment"
	@echo "  destroy-prod  - Destroy production environment"
	@echo "  validate      - Validate Terraform configuration"
	@echo "  format        - Format Terraform files"
	@echo "  clean         - Clean Terraform temporary files"

# Backend initialization
init-backend:
	@echo "Initializing Terraform backend..."
	cd terraform/shared && terraform init
	cd terraform/shared && terraform plan
	@echo "Review the plan above, then run 'cd terraform/shared && terraform apply' to create backend resources"

# Environment initialization
init-dev:
	@echo "Initializing development environment..."
	cd terraform/environments/dev && terraform init

init-prod:
	@echo "Initializing production environment..."
	cd terraform/environments/prod && terraform init

# Planning
plan-dev:
	@echo "Planning development environment..."
	cd terraform/environments/dev && terraform plan -var-file="terraform.tfvars"

plan-prod:
	@echo "Planning production environment..."
	cd terraform/environments/prod && terraform plan -var-file="terraform.tfvars"

# Applying
apply-dev:
	@echo "Applying development environment..."
	cd terraform/environments/dev && terraform apply -var-file="terraform.tfvars"

apply-prod:
	@echo "Applying production environment..."
	cd terraform/environments/prod && terraform apply -var-file="terraform.tfvars"

# Destroying
destroy-dev:
	@echo "Destroying development environment..."
	cd terraform/environments/dev && terraform destroy -var-file="terraform.tfvars"

destroy-prod:
	@echo "Destroying production environment..."
	cd terraform/environments/prod && terraform destroy -var-file="terraform.tfvars"

# Validation and formatting
validate:
	@echo "Validating Terraform configuration..."
	cd terraform/modules/networking && terraform validate
	cd terraform/environments/dev && terraform validate
	cd terraform/environments/prod && terraform validate

format:
	@echo "Formatting Terraform files..."
	terraform fmt -recursive terraform/

# Cleanup
clean:
	@echo "Cleaning Terraform temporary files..."
	find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.tfplan" -type f -delete 2>/dev/null || true
	find . -name ".terraform.lock.hcl" -type f -delete 2>/dev/null || true