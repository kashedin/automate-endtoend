# AWS Provider Configuration

provider "aws" {
  region = var.aws_region

  # Default tags applied to all resources
  default_tags {
    tags = {
      Project     = "automated-cloud-infrastructure"
      ManagedBy   = "terraform"
      Environment = var.environment
      Owner       = var.owner
      CostCenter  = var.cost_center
      Department  = var.department
      BillingCode = var.billing_code
    }
  }
}

# Variables for provider configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"

  validation {
    condition = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be in the format: us-east-1, eu-west-1, etc."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "devops-team"
}

variable "cost_center" {
  description = "Cost center for resource allocation"
  type        = string
  default     = "engineering"

  validation {
    condition     = contains(["engineering", "operations", "shared-services"], var.cost_center)
    error_message = "Cost center must be one of: engineering, operations, shared-services."
  }
}

variable "department" {
  description = "Department responsible for the resources"
  type        = string
  default     = "IT"
}

variable "billing_code" {
  description = "Billing code for cost tracking"
  type        = string
  default     = "PROJ-001"
}