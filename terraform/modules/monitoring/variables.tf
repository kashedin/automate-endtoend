# Monitoring Module Variables

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metrics"
  type        = string
}

variable "web_asg_name" {
  description = "Web tier Auto Scaling Group name"
  type        = string
}

variable "app_asg_name" {
  description = "App tier Auto Scaling Group name"
  type        = string
}

variable "db_cluster_identifier" {
  description = "RDS cluster identifier"
  type        = string
}

variable "web_scale_up_policy_arn" {
  description = "Web tier scale up policy ARN"
  type        = string
}

variable "web_scale_down_policy_arn" {
  description = "Web tier scale down policy ARN"
  type        = string
}

variable "app_scale_up_policy_arn" {
  description = "App tier scale up policy ARN"
  type        = string
}

variable "app_scale_down_policy_arn" {
  description = "App tier scale down policy ARN"
  type        = string
}

variable "alert_email_addresses" {
  description = "List of email addresses for alerts"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

# Alarm thresholds
variable "alarm_thresholds" {
  description = "CloudWatch alarm thresholds"
  type = object({
    alb_response_time_threshold    = number
    alb_5xx_error_threshold       = number
    ec2_cpu_high_threshold        = number
    ec2_cpu_low_threshold         = number
    rds_cpu_threshold             = number
    rds_connections_threshold     = number
    rds_read_latency_threshold    = number
  })
  
  default = {
    alb_response_time_threshold    = 1.0
    alb_5xx_error_threshold       = 10
    ec2_cpu_high_threshold        = 80
    ec2_cpu_low_threshold         = 20
    rds_cpu_threshold             = 80
    rds_connections_threshold     = 80
    rds_read_latency_threshold    = 0.2
  }
}