# Storage Module Variables

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "force_destroy_buckets" {
  description = "Force destroy S3 buckets even if they contain objects"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Number of days to retain log files"
  type        = number
  default     = 90
}

variable "backup_retention_days" {
  description = "Number of days to retain backup files"
  type        = number
  default     = 365
}

# Cross-region replication variable removed - disabled for sandbox compliance



variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

# Bucket configuration
variable "bucket_config" {
  description = "S3 bucket configuration"
  type = object({
    versioning_enabled   = bool
    encryption_enabled   = bool
    public_read_enabled  = bool
    lifecycle_enabled    = bool
    logging_enabled      = bool
    enable_notifications = optional(bool, false)
    destination_bucket   = optional(string, "")
  })

  default = {
    versioning_enabled   = true
    encryption_enabled   = true
    public_read_enabled  = false
    lifecycle_enabled    = true
    logging_enabled      = true
    enable_notifications = false
    destination_bucket   = ""
  }
}

