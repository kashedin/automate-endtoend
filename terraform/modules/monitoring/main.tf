# Monitoring Module - CloudWatch Dashboards, Alarms, SNS
# This module creates comprehensive monitoring and alerting

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# CloudWatch Dashboard for Infrastructure Overview
resource "aws_cloudwatch_dashboard" "infrastructure" {
  dashboard_name = "${var.environment}-infrastructure-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Application Load Balancer Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", var.web_asg_name],
            [".", "GroupInServiceInstances", ".", "."],
            [".", "GroupTotalInstances", ".", "."],
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", var.app_asg_name],
            [".", "GroupInServiceInstances", ".", "."],
            [".", "GroupTotalInstances", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Auto Scaling Group Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBClusterIdentifier", var.db_cluster_identifier],
            [".", "DatabaseConnections", ".", "."],
            [".", "ReadLatency", ".", "."],
            [".", "WriteLatency", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Aurora Database Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.web_asg_name],
            [".", "NetworkIn", ".", "."],
            [".", "NetworkOut", ".", "."],
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.app_asg_name],
            [".", "NetworkIn", ".", "."],
            [".", "NetworkOut", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "EC2 Instance Metrics"
          period  = 300
        }
      }
    ]
  })
}

# CloudWatch Dashboard for Application Performance
resource "aws_cloudwatch_dashboard" "application" {
  dashboard_name = "${var.environment}-application-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "log"
        x      = 0
        y      = 0
        width  = 24
        height = 6

        properties = {
          query  = "SOURCE '/aws/ec2/${var.environment}/web/httpd/access' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region = data.aws_region.current.name
          title  = "Recent Web Server Access Logs"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6

        properties = {
          query  = "SOURCE '/aws/ec2/${var.environment}/app/application' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region = data.aws_region.current.name
          title  = "Recent Application Logs"
        }
      }
    ]
  })
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-infrastructure-alerts"

  tags = merge(var.common_tags, {
    Name = "${var.environment}-infrastructure-alerts"
  })
}

# SNS Topic Subscription for Email
resource "aws_sns_topic_subscription" "email_alerts" {
  count = length(var.alert_email_addresses)

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email_addresses[count.index]
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "web_access" {
  name              = "/aws/ec2/${var.environment}/web/httpd/access"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name = "${var.environment}-web-access-logs"
  })
}

resource "aws_cloudwatch_log_group" "web_error" {
  name              = "/aws/ec2/${var.environment}/web/httpd/error"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name = "${var.environment}-web-error-logs"
  })
}

resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/${var.environment}/app/application"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name = "${var.environment}-app-logs"
  })
}

# CloudWatch Alarms

# ALB High Response Time Alarm
resource "aws_cloudwatch_metric_alarm" "alb_high_response_time" {
  alarm_name          = "${var.environment}-alb-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = var.alarm_thresholds.alb_response_time_threshold
  alarm_description   = "This metric monitors ALB response time"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-alb-high-response-time"
  })
}

# ALB High 5XX Error Rate Alarm
resource "aws_cloudwatch_metric_alarm" "alb_high_5xx_errors" {
  alarm_name          = "${var.environment}-alb-high-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.alarm_thresholds.alb_5xx_error_threshold
  alarm_description   = "This metric monitors ALB 5XX errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-alb-high-5xx-errors"
  })
}

# EC2 High CPU Utilization Alarm - Web Tier
resource "aws_cloudwatch_metric_alarm" "web_high_cpu" {
  alarm_name          = "${var.environment}-web-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.alarm_thresholds.ec2_cpu_high_threshold
  alarm_description   = "This metric monitors web tier CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn, var.web_scale_up_policy_arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.web_asg_name
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-web-high-cpu"
  })
}

# EC2 Low CPU Utilization Alarm - Web Tier
resource "aws_cloudwatch_metric_alarm" "web_low_cpu" {
  alarm_name          = "${var.environment}-web-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.alarm_thresholds.ec2_cpu_low_threshold
  alarm_description   = "This metric monitors web tier CPU utilization for scale down"
  alarm_actions       = [var.web_scale_down_policy_arn]

  dimensions = {
    AutoScalingGroupName = var.web_asg_name
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-web-low-cpu"
  })
}

# EC2 High CPU Utilization Alarm - App Tier
resource "aws_cloudwatch_metric_alarm" "app_high_cpu" {
  alarm_name          = "${var.environment}-app-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.alarm_thresholds.ec2_cpu_high_threshold
  alarm_description   = "This metric monitors app tier CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn, var.app_scale_up_policy_arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = var.app_asg_name
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-app-high-cpu"
  })
}

# EC2 Low CPU Utilization Alarm - App Tier
resource "aws_cloudwatch_metric_alarm" "app_low_cpu" {
  alarm_name          = "${var.environment}-app-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.alarm_thresholds.ec2_cpu_low_threshold
  alarm_description   = "This metric monitors app tier CPU utilization for scale down"
  alarm_actions       = [var.app_scale_down_policy_arn]

  dimensions = {
    AutoScalingGroupName = var.app_asg_name
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-app-low-cpu"
  })
}

# RDS High CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu" {
  alarm_name          = "${var.environment}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.alarm_thresholds.rds_cpu_threshold
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBClusterIdentifier = var.db_cluster_identifier
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-rds-high-cpu"
  })
}

# RDS High Database Connections Alarm
resource "aws_cloudwatch_metric_alarm" "rds_high_connections" {
  alarm_name          = "${var.environment}-rds-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.alarm_thresholds.rds_connections_threshold
  alarm_description   = "This metric monitors RDS database connections"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBClusterIdentifier = var.db_cluster_identifier
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-rds-high-connections"
  })
}

# RDS High Read Latency Alarm
resource "aws_cloudwatch_metric_alarm" "rds_high_read_latency" {
  alarm_name          = "${var.environment}-rds-high-read-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.alarm_thresholds.rds_read_latency_threshold
  alarm_description   = "This metric monitors RDS read latency"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBClusterIdentifier = var.db_cluster_identifier
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-rds-high-read-latency"
  })
}

# Data source for current region
data "aws_region" "current" {}