# Networking Module Variables

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnets are required for high availability."
  }
}

variable "private_web_subnet_cidrs" {
  description = "CIDR blocks for private web tier subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]

  validation {
    condition     = length(var.private_web_subnet_cidrs) >= 2
    error_message = "At least 2 private web subnets are required for high availability."
  }
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private app tier subnets"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]

  validation {
    condition     = length(var.private_app_subnet_cidrs) >= 2
    error_message = "At least 2 private app subnets are required for high availability."
  }
}

variable "private_data_subnet_cidrs" {
  description = "CIDR blocks for private data tier subnets"
  type        = list(string)
  default     = ["10.0.30.0/24", "10.0.31.0/24"]

  validation {
    condition     = length(var.private_data_subnet_cidrs) >= 2
    error_message = "At least 2 private data subnets are required for high availability."
  }
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}