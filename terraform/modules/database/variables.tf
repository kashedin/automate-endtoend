# Database Module Variables

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for database"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for database access"
  type        = string
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "appdb"
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
  default     = "admin"
}

variable "master_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (optional)"
  type        = string
  default     = null
}

variable "monitoring_role_arn" {
  description = "IAM role ARN for enhanced monitoring (optional)"
  type        = string
  default     = null
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

# Aurora configuration
variable "aurora_config" {
  description = "Aurora MySQL database configuration"
  type = object({
    engine                       = string
    engine_version               = string
    instance_class               = string
    storage_encrypted            = bool
    backup_retention_period      = number
    backup_window                = string
    maintenance_window           = string
    monitoring_interval          = number
    performance_insights_enabled = bool
    deletion_protection          = bool
    skip_final_snapshot          = bool
    copy_tags_to_snapshot        = bool
    reader_count                 = number
    auto_scaling_enabled         = bool
    auto_scaling_min_capacity    = number
    auto_scaling_max_capacity    = number
    serverless_enabled           = bool
    global_cluster_enabled       = bool
  })

  default = {
    engine                       = "aurora-mysql"
    engine_version               = "8.0.mysql_aurora.3.04.0"
    instance_class               = "db.t3.medium"
    storage_encrypted            = true
    backup_retention_period      = 7
    backup_window                = "03:00-04:00"
    maintenance_window           = "sun:04:00-sun:05:00"
    monitoring_interval          = 60
    performance_insights_enabled = true
    deletion_protection          = false
    skip_final_snapshot          = false
    copy_tags_to_snapshot        = true
    reader_count                 = 1
    auto_scaling_enabled         = true
    auto_scaling_min_capacity    = 1
    auto_scaling_max_capacity    = 3
    serverless_enabled           = false
    global_cluster_enabled       = false
  }

  validation {
    condition     = contains(["aurora-mysql"], var.aurora_config.engine)
    error_message = "Engine must be aurora-mysql."
  }

  validation {
    condition     = var.aurora_config.backup_retention_period >= 1 && var.aurora_config.backup_retention_period <= 35
    error_message = "Backup retention period must be between 1 and 35 days."
  }

  validation {
    condition     = var.aurora_config.reader_count >= 0 && var.aurora_config.reader_count <= 15
    error_message = "Reader count must be between 0 and 15."
  }
}