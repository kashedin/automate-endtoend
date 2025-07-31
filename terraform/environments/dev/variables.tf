# Development Environment Variables

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "devops-team"
}

# Networking Variables
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_web_subnet_cidrs" {
  description = "CIDR blocks for private web tier subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private app tier subnets"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "private_data_subnet_cidrs" {
  description = "CIDR blocks for private data tier subnets"
  type        = list(string)
  default     = ["10.0.30.0/24", "10.0.31.0/24"]
}

# Environment Configuration
variable "environment_config" {
  description = "Environment-specific configuration"
  type = object({
    name                = string
    instance_type       = string
    min_capacity        = number
    max_capacity        = number
    desired_capacity    = number
    db_instance_class   = string
    backup_retention    = number
    monitoring_enabled  = bool
    cost_alerts_enabled = bool
  })
  
  default = {
    name                = "dev"
    instance_type       = "t3.micro"
    min_capacity        = 1
    max_capacity        = 3
    desired_capacity    = 2
    db_instance_class   = "db.t3.medium"
    backup_retention    = 7
    monitoring_enabled  = true
    cost_alerts_enabled = false
  }
}

# Auto Scaling Group configuration
variable "web_asg_config" {
  description = "Web tier Auto Scaling Group configuration"
  type = object({
    min_size         = number
    max_size         = number
    desired_capacity = number
  })
  default = {
    min_size         = 1
    max_size         = 2
    desired_capacity = 1
  }
}

variable "app_asg_config" {
  description = "App tier Auto Scaling Group configuration"
  type = object({
    min_size         = number
    max_size         = number
    desired_capacity = number
  })
  default = {
    min_size         = 1
    max_size         = 2
    desired_capacity = 1
  }
}

# Aurora configuration
variable "aurora_config" {
  description = "Aurora MySQL database configuration"
  type = object({
    engine                        = string
    engine_version               = string
    instance_class               = string
    storage_encrypted            = bool
    backup_retention_period      = number
    backup_window               = string
    maintenance_window          = string
    monitoring_interval         = number
    performance_insights_enabled = bool
    deletion_protection         = bool
    skip_final_snapshot         = bool
    copy_tags_to_snapshot       = bool
    reader_count                = number
    auto_scaling_enabled        = bool
    auto_scaling_min_capacity   = number
    auto_scaling_max_capacity   = number
    serverless_enabled          = bool
    global_cluster_enabled      = bool
  })
}

# Alert email addresses
variable "alert_email_addresses" {
  description = "List of email addresses for alerts"
  type        = list(string)
  default     = []
}