# Monitoring Module Outputs

# CloudWatch Dashboards
output "infrastructure_dashboard_url" {
  description = "URL of the infrastructure CloudWatch dashboard"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.infrastructure.dashboard_name}"
}

output "application_dashboard_url" {
  description = "URL of the application CloudWatch dashboard"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.application.dashboard_name}"
}

# SNS Topic
output "alerts_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = aws_sns_topic.alerts.arn
}

output "alerts_topic_name" {
  description = "Name of the SNS alerts topic"
  value       = aws_sns_topic.alerts.name
}

# CloudWatch Log Groups
output "log_group_names" {
  description = "Map of CloudWatch log group names"
  value = {
    web_access = aws_cloudwatch_log_group.web_access.name
    web_error  = aws_cloudwatch_log_group.web_error.name
    app_logs   = aws_cloudwatch_log_group.app_logs.name
  }
}

output "log_group_arns" {
  description = "Map of CloudWatch log group ARNs"
  value = {
    web_access = aws_cloudwatch_log_group.web_access.arn
    web_error  = aws_cloudwatch_log_group.web_error.arn
    app_logs   = aws_cloudwatch_log_group.app_logs.arn
  }
}

# CloudWatch Alarms
output "alarm_names" {
  description = "List of CloudWatch alarm names"
  value = [
    aws_cloudwatch_metric_alarm.alb_high_response_time.alarm_name,
    aws_cloudwatch_metric_alarm.alb_high_5xx_errors.alarm_name,
    aws_cloudwatch_metric_alarm.web_high_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.web_low_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.app_high_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.app_low_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.rds_high_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.rds_high_connections.alarm_name,
    aws_cloudwatch_metric_alarm.rds_high_read_latency.alarm_name
  ]
}

output "alarm_arns" {
  description = "Map of CloudWatch alarm ARNs"
  value = {
    alb_high_response_time = aws_cloudwatch_metric_alarm.alb_high_response_time.arn
    alb_high_5xx_errors   = aws_cloudwatch_metric_alarm.alb_high_5xx_errors.arn
    web_high_cpu          = aws_cloudwatch_metric_alarm.web_high_cpu.arn
    web_low_cpu           = aws_cloudwatch_metric_alarm.web_low_cpu.arn
    app_high_cpu          = aws_cloudwatch_metric_alarm.app_high_cpu.arn
    app_low_cpu           = aws_cloudwatch_metric_alarm.app_low_cpu.arn
    rds_high_cpu          = aws_cloudwatch_metric_alarm.rds_high_cpu.arn
    rds_high_connections  = aws_cloudwatch_metric_alarm.rds_high_connections.arn
    rds_high_read_latency = aws_cloudwatch_metric_alarm.rds_high_read_latency.arn
  }
}