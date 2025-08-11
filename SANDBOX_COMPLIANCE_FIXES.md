# AWS Academy Sandbox Compliance Fixes

## Overview
This document outlines the changes made to ensure the CloudFront CDN infrastructure is compliant with AWS Academy Sandbox constraints as defined in `notneeded/sandbox.txt`.

## Key Sandbox Constraints
1. **IAM Role Creation Restricted** - Must use existing `LabRole` and `LabInstanceProfile`
2. **KMS Access** - Read-only access only
3. **Instance Types** - Limited to t2/t3 nano to medium
4. **WAF Not Available** - Not listed in allowed services
5. **Service Limitations** - Various service-specific restrictions

## Fixes Applied

### 1. ✅ Removed WAF Configuration
**Files Modified:**
- `terraform/modules/compute/main.tf`

**Changes:**
- Removed `aws_wafv2_web_acl` resource
- Removed `aws_wafv2_web_acl_logging_configuration` resource  
- Removed `aws_wafv2_web_acl_association` resource
- Removed WAF CloudWatch log group
- Added comment explaining WAF is not available in sandbox

**Impact:** Security now relies on security groups instead of WAF

### 2. ✅ Fixed IAM Role Usage
**Files Modified:**
- `terraform/modules/security/main.tf`
- `terraform/modules/security/outputs.tf`

**Changes:**
- Replaced custom instance profile creation with existing `LabInstanceProfile`
- Updated outputs to reference existing instance profile
- Added data source for `LabInstanceProfile`

**Impact:** Uses sandbox-compliant IAM resources

### 3. ✅ Disabled VPC Flow Logs
**Files Modified:**
- `terraform/modules/networking/main.tf`

**Changes:**
- Removed custom IAM role for VPC Flow Logs
- Removed VPC Flow Logs configuration
- Removed associated CloudWatch log group and KMS key
- Added comment explaining restriction

**Impact:** VPC Flow Logs disabled due to IAM role restrictions

### 4. ✅ Disabled AWS Backup
**Files Modified:**
- `terraform/modules/database/main.tf`

**Changes:**
- Removed `aws_backup_vault` resource
- Removed `aws_backup_plan` resource
- Removed custom backup IAM role
- Removed backup selection configuration
- Added comment explaining restriction

**Impact:** Relies on RDS automated backups instead of AWS Backup

### 5. ✅ Disabled Custom KMS Keys
**Files Modified:**
- `terraform/modules/security/main.tf`
- `terraform/modules/storage/main.tf` (S3 KMS)
- `terraform/modules/monitoring/main.tf` (CloudWatch KMS)

**Changes:**
- Removed custom KMS key creation for SSM parameters
- Updated SSM parameters to use default AWS managed keys
- Disabled S3 bucket KMS encryption (uses AES256 instead)
- Disabled CloudWatch logs KMS encryption

**Impact:** Uses default AWS managed encryption instead of custom KMS keys

### 6. ✅ Disabled S3 Cross-Region Replication
**Files Modified:**
- `terraform/modules/storage/main.tf`

**Changes:**
- Removed custom IAM role for S3 replication
- Disabled replication configuration
- Added comment explaining restriction

**Impact:** No cross-region replication due to IAM role restrictions

### 7. ✅ Verified Instance Types
**Files Checked:**
- `terraform/environments/dev/terraform.tfvars` - Uses `t3.micro` ✅
- `terraform/environments/prod/terraform.tfvars` - Uses `t3.small` ✅

**Status:** Already compliant with t2/t3 nano to medium restriction

## CloudFront CDN Features Retained

### ✅ Core CloudFront Functionality
- CloudFront distribution with global edge locations
- ALB primary origin configuration
- S3 static website failover
- HTTPS-only access with automatic redirect
- Origin Access Control (OAC) for S3
- Security headers policy
- Cost-optimized price classes

### ✅ Security Features (Sandbox-Compliant)
- HTTPS enforcement with TLS 1.2+
- Strict Transport Security (HSTS) headers
- Content Security Policy headers
- X-Frame-Options protection
- Security groups for network protection

## Deployment Verification

### Before Deployment
1. **AWS Academy Lab Started** ✅
2. **Credentials Configured** ✅
3. **GitHub Secrets Set** ✅
4. **Sandbox Constraints Reviewed** ✅

### Expected Deployment Results
- ✅ CloudFront distribution with HTTPS-only access
- ✅ ALB primary origin with EC2 instances
- ✅ S3 static website failover
- ✅ Security groups protecting all tiers
- ✅ RDS database with automated backups
- ✅ All resources using LabRole/LabInstanceProfile

## Testing Commands

```bash
# Validate Terraform configuration
terraform validate

# Check for sandbox compliance
terraform plan

# Deploy infrastructure
terraform apply

# Test CloudFront URL
curl -I https://[cloudfront-domain]

# Test failover (when ALB is down)
curl -I https://[cloudfront-domain]
```

## Cost Optimization for Sandbox

### Instance Configuration
- **Dev Environment**: t3.micro instances
- **Prod Environment**: t3.small instances (within limits)
- **Auto Scaling**: Limited to 6 instances max per ASG

### Storage Configuration
- **S3**: Standard storage class
- **RDS**: db.t3.micro for dev, db.t3.small for prod
- **EBS**: General Purpose SSD (gp2) up to 100GB

### CloudFront Configuration
- **Price Class**: PriceClass_100 (US, Canada, Europe only)
- **Caching**: Optimized TTL settings
- **Compression**: Enabled for bandwidth savings

## Monitoring (Sandbox-Compliant)

### Available Monitoring
- ✅ CloudWatch basic metrics
- ✅ ALB health checks
- ✅ RDS automated backups
- ✅ S3 access logging
- ✅ CloudFront access logs

### Disabled Monitoring
- ❌ VPC Flow Logs (IAM role restriction)
- ❌ WAF logs (WAF not available)
- ❌ Enhanced RDS monitoring (cost optimization)
- ❌ Custom KMS key metrics

## Summary

The CloudFront CDN infrastructure has been successfully adapted for AWS Academy Sandbox compliance while retaining all core functionality:

- **Security**: Maintained through security groups and HTTPS enforcement
- **Performance**: CloudFront global distribution with edge caching
- **Reliability**: ALB primary with S3 failover
- **Cost**: Optimized for sandbox budget constraints
- **Compliance**: All sandbox restrictions addressed

The architecture is now ready for deployment in the AWS Academy Sandbox environment! 🚀