# Compute Module Variables

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "web_subnet_ids" {
  description = "List of private web subnet IDs"
  type        = list(string)
}

variable "app_subnet_ids" {
  description = "List of private app subnet IDs"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "web_security_group_id" {
  description = "Security group ID for web tier"
  type        = string
}

variable "app_security_group_id" {
  description = "Security group ID for app tier"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
}

variable "database_endpoint" {
  description = "Database endpoint for application configuration"
  type        = string
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = null
}

variable "web_instance_type" {
  description = "Instance type for web tier"
  type        = string
  default     = "t3.micro"
}

variable "app_instance_type" {
  description = "Instance type for app tier"
  type        = string
  default     = "t3.micro"
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
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
    max_size         = 3
    desired_capacity = 2
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
    max_size         = 3
    desired_capacity = 2
  }
}variab
le "alb_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
  default     = ""
}