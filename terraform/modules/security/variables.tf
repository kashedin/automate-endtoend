# Security Module Variables

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "lab_role_name" {
  description = "Name of the existing lab role to use"
  type        = string
  default     = "labrole"
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

# Security group rules configuration
variable "security_rules" {
  description = "Security group rules configuration"
  type = map(object({
    type        = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = {}
}

variable "enable_ssh_access" {
  description = "Enable SSH access to instances"
  type        = bool
  default     = true
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = []
}

variable "allowed_http_cidrs" {
  description = "CIDR blocks allowed for HTTP access to ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Database configuration
variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

# Application parameters for Parameter Store
variable "app_parameters" {
  description = "Application parameters to store in Parameter Store"
  type = map(object({
    value = string
    type  = string
  }))
  default = {
    "log_level" = {
      value = "INFO"
      type  = "String"
    }
    "max_connections" = {
      value = "100"
      type  = "String"
    }
  }
}