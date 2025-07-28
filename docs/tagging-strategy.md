# Resource Tagging Strategy

## Overview

This document outlines the standardized tagging strategy for the Automated Cloud Infrastructure project. Consistent tagging enables cost tracking, resource management, automation, and compliance across all AWS resources.

## Tagging Standards

### Required Tags

All resources MUST include the following tags:

| Tag Key | Description | Example Values |
|---------|-------------|----------------|
| `Project` | Project identifier | `automated-cloud-infrastructure` |
| `Environment` | Environment name | `dev`, `staging`, `prod` |
| `ManagedBy` | Management method | `terraform` |
| `Owner` | Resource owner/team | `devops-team`, `platform-team` |
| `CostCenter` | Cost allocation | `engineering`, `operations` |

### Optional Tags

Additional tags for enhanced organization:

| Tag Key | Description | Example Values |
|---------|-------------|----------------|
| `Tier` | Application tier | `web`, `app`, `data`, `public` |
| `Purpose` | Resource purpose | `load-balancer`, `database`, `storage` |
| `Backup` | Backup requirement | `daily`, `weekly`, `none` |
| `Monitoring` | Monitoring level | `basic`, `enhanced`, `critical` |
| `Compliance` | Compliance requirements | `pci`, `hipaa`, `sox` |
| `Schedule` | Operating schedule | `24x7`, `business-hours`, `on-demand` |

## Implementation

### Terraform Configuration

#### Provider-Level Default Tags

```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "automated-cloud-infrastructure"
      ManagedBy   = "terraform"
      Environment = var.environment
      Owner       = var.owner
      CostCenter  = var.cost_center
    }
  }
}
```

#### Module-Level Tags

```hcl
locals {
  common_tags = {
    Environment = var.environment
    Project     = "automated-cloud-infrastructure"
    ManagedBy   = "terraform"
    Owner       = var.owner
    CostCenter  = var.cost_center
    Tier        = var.tier
    Purpose     = var.purpose
  }
}

resource "aws_instance" "example" {
  # ... other configuration

  tags = merge(local.common_tags, {
    Name = "${var.environment}-${var.tier}-instance"
    Backup = "daily"
    Monitoring = "enhanced"
  })
}
```

## Tag Naming Conventions

### General Rules

1. **Case Sensitivity**: Use PascalCase for tag keys (e.g., `CostCenter`, `BackupSchedule`)
2. **Consistency**: Use consistent values across all resources
3. **No Spaces**: Avoid spaces in tag keys and values
4. **Descriptive**: Use descriptive but concise tag values
5. **Standardized Values**: Use predefined values from approved lists

### Environment Values

- `dev` - Development environment
- `staging` - Staging/testing environment
- `prod` - Production environment

### Tier Values

- `public` - Public-facing resources (ALB, CloudFront)
- `web` - Web tier resources (web servers)
- `app` - Application tier resources (app servers)
- `data` - Data tier resources (databases, caches)

### Purpose Values

- `load-balancer` - Load balancing resources
- `compute` - Compute resources (EC2, Lambda)
- `database` - Database resources
- `storage` - Storage resources (S3, EBS)
- `networking` - Network resources (VPC, subnets)
- `security` - Security resources (security groups, IAM)
- `monitoring` - Monitoring resources (CloudWatch, SNS)

## Cost Allocation Strategy

### Cost Center Mapping

| Cost Center | Description | Resources |
|-------------|-------------|-----------|
| `engineering` | Development and testing | Dev environment resources |
| `operations` | Production operations | Prod environment resources |
| `shared-services` | Shared infrastructure | Monitoring, logging, backup |

### Cost Tracking Tags

Use these tags for detailed cost analysis:

```hcl
tags = {
  CostCenter    = "engineering"
  Project       = "automated-cloud-infrastructure"
  Environment   = "dev"
  Owner         = "devops-team"
  BillingCode   = "PROJ-001"
  Department    = "IT"
}
```

## Automation and Governance

### Tag Compliance

1. **AWS Config Rules**: Implement Config rules to enforce required tags
2. **IAM Policies**: Use IAM policies to require tags on resource creation
3. **Cost Allocation Tags**: Activate cost allocation tags in AWS Billing

### Example Config Rule

```json
{
  "ConfigRuleName": "required-tags",
  "Source": {
    "Owner": "AWS",
    "SourceIdentifier": "REQUIRED_TAGS"
  },
  "InputParameters": {
    "requiredTagKeys": "Project,Environment,Owner,ManagedBy"
  }
}
```

### Example IAM Policy

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "ec2:RunInstances",
        "rds:CreateDBInstance",
        "s3:CreateBucket"
      ],
      "Resource": "*",
      "Condition": {
        "Null": {
          "aws:RequestedRegion": "false",
          "aws:RequestTag/Project": "true"
        }
      }
    }
  ]
}
```

## Monitoring and Reporting

### Cost Reports

Generate cost reports using these tag dimensions:

1. **By Environment**: Track costs per environment
2. **By Tier**: Understand tier-specific costs
3. **By Owner**: Allocate costs to teams
4. **By Purpose**: Analyze costs by resource type

### CloudWatch Dashboards

Create dashboards filtered by tags:

```hcl
resource "aws_cloudwatch_dashboard" "cost_by_environment" {
  dashboard_name = "cost-by-environment"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD", "Environment", "dev"],
            [".", ".", ".", ".", ".", "prod"]
          ]
          title = "Cost by Environment"
        }
      }
    ]
  })
}
```

## Best Practices

### Do's

1. ✅ Apply tags consistently across all resources
2. ✅ Use automation to enforce tagging policies
3. ✅ Review and update tags regularly
4. ✅ Document tag meanings and usage
5. ✅ Use tags for cost allocation and chargeback
6. ✅ Implement tag-based access controls

### Don'ts

1. ❌ Don't use sensitive information in tag values
2. ❌ Don't create too many custom tags without governance
3. ❌ Don't use inconsistent tag values
4. ❌ Don't forget to tag all billable resources
5. ❌ Don't use spaces or special characters in tag keys
6. ❌ Don't create tags without clear business purpose

## Tag Validation

### Terraform Validation

```hcl
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  
  validation {
    condition = alltrue([
      contains(keys(var.common_tags), "Project"),
      contains(keys(var.common_tags), "Environment"),
      contains(keys(var.common_tags), "Owner"),
      contains(keys(var.common_tags), "ManagedBy")
    ])
    error_message = "Required tags must include: Project, Environment, Owner, ManagedBy."
  }
}
```

### Pre-commit Hooks

```bash
#!/bin/bash
# Check for required tags in Terraform files
required_tags=("Project" "Environment" "Owner" "ManagedBy")

for tag in "${required_tags[@]}"; do
  if ! grep -r "tags.*$tag" terraform/; then
    echo "Error: Required tag '$tag' not found in Terraform files"
    exit 1
  fi
done
```

## Migration Strategy

### Existing Resources

1. **Audit**: Identify untagged resources
2. **Prioritize**: Tag critical resources first
3. **Automate**: Use scripts to bulk-tag resources
4. **Validate**: Verify tag compliance

### Bulk Tagging Script

```bash
#!/bin/bash
# Bulk tag EC2 instances
aws ec2 create-tags \
  --resources $(aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId' --output text) \
  --tags Key=Project,Value=automated-cloud-infrastructure \
         Key=ManagedBy,Value=terraform
```

## Conclusion

Consistent resource tagging is essential for:

- **Cost Management**: Accurate cost allocation and optimization
- **Resource Organization**: Easy resource discovery and management
- **Automation**: Tag-based automation and policies
- **Compliance**: Meeting governance and audit requirements
- **Operations**: Efficient monitoring and troubleshooting

This tagging strategy should be reviewed quarterly and updated as needed to meet evolving business requirements.