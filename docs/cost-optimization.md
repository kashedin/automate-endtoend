# Cost Optimization Guide

## Overview

This document provides comprehensive guidance on cost optimization strategies for the Automated Cloud Infrastructure project. It includes cost-effective resource selection, monitoring approaches, and optimization opportunities.

## Cost-Effective Architecture Decisions

### Compute Resources

#### Instance Types

| Tier | Environment | Instance Type | vCPU | Memory | Cost/Hour* | Rationale |
|------|-------------|---------------|------|--------|------------|-----------|
| Web | Development | t3.micro | 2 | 1 GB | $0.0104 | Burstable performance for low traffic |
| Web | Production | t3.small | 2 | 2 GB | $0.0208 | Better baseline performance |
| App | Development | t3.micro | 2 | 1 GB | $0.0104 | Cost-optimized for testing |
| App | Production | t3.small | 2 | 2 GB | $0.0208 | Adequate for moderate workloads |
| Database | All | db.t3.medium | 2 | 4 GB | $0.068 | Balanced compute and memory |

*Prices are approximate and vary by region

#### Auto Scaling Configuration

```hcl
# Development Environment - Cost Optimized
web_asg_config = {
  min_size         = 1    # Minimum instances to reduce costs
  max_size         = 2    # Limited scaling for dev
  desired_capacity = 1    # Start with single instance
}

# Production Environment - Performance Optimized
web_asg_config = {
  min_size         = 2    # High availability
  max_size         = 8    # Scale for peak loads
  desired_capacity = 3    # Adequate baseline capacity
}
```

### Database Resources

#### Aurora MySQL Configuration

| Environment | Instance Class | Backup Retention | Multi-AZ | Estimated Monthly Cost* |
|-------------|----------------|------------------|----------|------------------------|
| Development | db.t3.medium | 7 days | Yes | $45-60 |
| Production | db.t3.medium | 30 days | Yes | $50-70 |

*Costs include compute, storage, and backup

#### Cost Optimization Features

1. **Aurora Serverless**: Consider for variable workloads
2. **Read Replicas**: Only deploy when read performance is critical
3. **Backup Optimization**: Shorter retention for non-critical environments
4. **Storage Auto-scaling**: Automatic storage scaling prevents over-provisioning

### Storage Resources

#### S3 Storage Classes

| Bucket Purpose | Storage Class | Access Pattern | Cost/GB/Month* |
|----------------|---------------|----------------|----------------|
| Static Website | Standard | Frequent access | $0.023 |
| Application Logs | Standard-IA | Infrequent access | $0.0125 |
| Long-term Backups | Glacier | Archive | $0.004 |
| Compliance Data | Deep Archive | Rare access | $0.00099 |

*Prices are approximate for US East (N. Virginia)

#### Lifecycle Policies

```hcl
# Cost-optimized lifecycle configuration
lifecycle_configuration {
  rule {
    id     = "log_lifecycle"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

    # Move to IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Move to Glacier after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Delete after 365 days
    expiration {
      days = 365
    }
  }
}
```

### Network Resources

#### NAT Gateway Optimization

| Environment | NAT Gateways | Monthly Cost* | Optimization |
|-------------|--------------|---------------|--------------|
| Development | 1 per AZ (2) | $90 | Consider NAT instances for dev |
| Production | 1 per AZ (2) | $90 | Required for high availability |

*Includes data processing charges

## Cost Monitoring and Alerting

### Budget Configuration

```hcl
# Monthly budget alert
resource "aws_budgets_budget" "monthly_cost" {
  name         = "${var.environment}-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filters = {
    Tag = {
      Key    = "Environment"
      Values = [var.environment]
    }
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_emails
  }
}
```

### Cost Allocation Tags

Essential tags for cost tracking:

```hcl
default_tags = {
  Project     = "automated-cloud-infrastructure"
  Environment = var.environment
  Owner       = var.owner
  CostCenter  = var.cost_center
  Tier        = var.tier
  Purpose     = var.purpose
}
```

## Resource Right-Sizing

### EC2 Instance Optimization

#### Monitoring Metrics

1. **CPU Utilization**: Target 40-60% average utilization
2. **Memory Utilization**: Monitor with CloudWatch agent
3. **Network Utilization**: Check for over-provisioned bandwidth
4. **EBS Performance**: Monitor IOPS and throughput

#### Right-Sizing Recommendations

```bash
# AWS CLI command to get EC2 right-sizing recommendations
aws ce get-rightsizing-recommendation \
  --service EC2-Instance \
  --configuration '{
    "BenefitsConsidered": true,
    "RecommendationTarget": "SAME_INSTANCE_FAMILY"
  }'
```

### Database Optimization

#### Performance Monitoring

1. **CPU Utilization**: Keep below 80% for consistent performance
2. **Connection Count**: Monitor against connection limits
3. **Read/Write Latency**: Optimize queries for high latency
4. **Storage Growth**: Monitor and forecast storage needs

#### Aurora Specific Optimizations

```sql
-- Monitor expensive queries
SELECT * FROM performance_schema.events_statements_summary_by_digest
ORDER BY sum_timer_wait DESC LIMIT 10;

-- Check connection usage
SHOW STATUS LIKE 'Threads_connected';
SHOW VARIABLES LIKE 'max_connections';
```

## Cost Optimization Strategies

### 1. Reserved Instances and Savings Plans

#### EC2 Reserved Instances

| Instance Type | On-Demand | 1-Year Reserved | 3-Year Reserved | Savings |
|---------------|-----------|-----------------|-----------------|---------|
| t3.micro | $0.0104/hr | $0.0062/hr | $0.0042/hr | 60% |
| t3.small | $0.0208/hr | $0.0125/hr | $0.0083/hr | 60% |
| t3.medium | $0.0416/hr | $0.0250/hr | $0.0166/hr | 60% |

#### RDS Reserved Instances

```hcl
# Example reserved instance calculation
# db.t3.medium on-demand: $0.068/hour = $595/month
# db.t3.medium 1-year reserved: $0.041/hour = $359/month
# Annual savings: $2,832
```

### 2. Spot Instances

Consider Spot Instances for:
- Development environments
- Batch processing workloads
- Non-critical applications

```hcl
# Spot instance configuration
resource "aws_launch_template" "spot" {
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = "0.05"  # 50% of on-demand price
    }
  }
}
```

### 3. Auto Scaling Optimization

#### Predictive Scaling

```hcl
resource "aws_autoscaling_policy" "predictive" {
  name                   = "${var.environment}-predictive-scaling"
  policy_type           = "PredictiveScaling"
  autoscaling_group_name = aws_autoscaling_group.web.name

  predictive_scaling_configuration {
    metric_specification {
      target_value = 50.0
      predefined_metric_specification {
        predefined_metric_type = "ASGAverageCPUUtilization"
      }
    }
    mode                         = "ForecastAndScale"
    scheduling_buffer_time       = 300
    max_capacity_breach_behavior = "HonorMaxCapacity"
  }
}
```

### 4. Storage Optimization

#### EBS Volume Types

| Volume Type | Use Case | Cost/GB/Month* | IOPS |
|-------------|----------|----------------|------|
| gp3 | General purpose | $0.08 | 3,000-16,000 |
| gp2 | Legacy general purpose | $0.10 | 100-16,000 |
| io2 | High IOPS | $0.125 | Up to 64,000 |
| st1 | Throughput optimized | $0.045 | 500 |

*US East (N. Virginia) pricing

#### S3 Intelligent Tiering

```hcl
resource "aws_s3_bucket_intelligent_tiering_configuration" "example" {
  bucket = aws_s3_bucket.app_assets.id
  name   = "EntireBucket"

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 125
  }
}
```

## Environment-Specific Cost Strategies

### Development Environment

**Optimization Focus**: Minimize costs while maintaining functionality

1. **Scheduled Scaling**: Scale down during off-hours
2. **Smaller Instance Types**: Use t3.micro for most workloads
3. **Reduced Backup Retention**: 7 days instead of 30
4. **Single AZ Deployment**: For non-critical components

```hcl
# Development cost optimizations
variable "dev_optimizations" {
  default = {
    instance_type        = "t3.micro"
    backup_retention     = 7
    multi_az            = false
    monitoring_interval = 0  # Disable enhanced monitoring
  }
}
```

### Production Environment

**Optimization Focus**: Balance cost and performance

1. **Reserved Instances**: For predictable workloads
2. **Auto Scaling**: Efficient scaling based on demand
3. **Performance Monitoring**: Right-size based on actual usage
4. **Cost Allocation**: Detailed tagging for chargeback

```hcl
# Production optimizations
variable "prod_optimizations" {
  default = {
    instance_type        = "t3.small"
    backup_retention     = 30
    multi_az            = true
    monitoring_interval = 60
    reserved_instances  = true
  }
}
```

## Cost Monitoring Dashboard

### CloudWatch Dashboard Configuration

```hcl
resource "aws_cloudwatch_dashboard" "cost_monitoring" {
  dashboard_name = "${var.environment}-cost-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD", "Environment", var.environment]
          ]
          period = 86400
          stat   = "Maximum"
          region = "us-east-1"
          title  = "Daily Estimated Charges"
        }
      }
    ]
  })
}
```

## Cost Optimization Checklist

### Monthly Review

- [ ] Review AWS Cost Explorer for spending trends
- [ ] Analyze unused or underutilized resources
- [ ] Check for unattached EBS volumes
- [ ] Review data transfer costs
- [ ] Validate Reserved Instance utilization
- [ ] Check for idle load balancers
- [ ] Review S3 storage class distribution

### Quarterly Review

- [ ] Evaluate Reserved Instance renewals
- [ ] Review instance right-sizing recommendations
- [ ] Analyze cost allocation by tags
- [ ] Update budget thresholds
- [ ] Review and optimize data retention policies
- [ ] Evaluate new AWS cost optimization features

### Annual Review

- [ ] Comprehensive architecture cost review
- [ ] Evaluate Savings Plans vs Reserved Instances
- [ ] Review and update cost optimization strategies
- [ ] Benchmark costs against industry standards
- [ ] Plan for upcoming AWS price changes

## Cost Optimization Tools

### AWS Native Tools

1. **AWS Cost Explorer**: Analyze spending patterns
2. **AWS Budgets**: Set up cost and usage budgets
3. **AWS Trusted Advisor**: Get cost optimization recommendations
4. **AWS Compute Optimizer**: Right-size EC2 instances
5. **AWS Cost Anomaly Detection**: Detect unusual spending

### Third-Party Tools

1. **CloudHealth**: Multi-cloud cost management
2. **CloudCheckr**: Cost optimization and governance
3. **ParkMyCloud**: Automated resource scheduling
4. **Spot.io**: Spot instance management

## Conclusion

Cost optimization is an ongoing process that requires:

1. **Continuous Monitoring**: Regular review of costs and usage
2. **Right-Sizing**: Match resources to actual requirements
3. **Automation**: Use auto-scaling and scheduling
4. **Reserved Capacity**: Purchase reserved instances for predictable workloads
5. **Storage Optimization**: Use appropriate storage classes and lifecycle policies
6. **Tagging Strategy**: Implement comprehensive cost allocation tags

By following these guidelines and regularly reviewing costs, you can achieve significant savings while maintaining performance and reliability.

## Estimated Monthly Costs

### Development Environment

| Service | Resource | Quantity | Monthly Cost |
|---------|----------|----------|--------------|
| EC2 | t3.micro instances | 2-4 | $15-30 |
| RDS | db.t3.medium Aurora | 1 cluster | $45-60 |
| ALB | Application Load Balancer | 1 | $18 |
| NAT Gateway | NAT Gateways | 2 | $90 |
| S3 | Storage (100GB) | - | $3 |
| CloudWatch | Logs and metrics | - | $10 |
| **Total** | | | **$181-211** |

### Production Environment

| Service | Resource | Quantity | Monthly Cost |
|---------|----------|----------|--------------|
| EC2 | t3.small instances | 4-8 | $60-120 |
| RDS | db.t3.medium Aurora | 1 cluster | $50-70 |
| ALB | Application Load Balancer | 1 | $18 |
| NAT Gateway | NAT Gateways | 2 | $90 |
| S3 | Storage (500GB) | - | $15 |
| CloudWatch | Enhanced monitoring | - | $25 |
| **Total** | | | **$258-338** |

*Costs are estimates and may vary based on actual usage, region, and AWS pricing changes.*