# 🧹 Infrastructure Cleanup Guide

## Overview
This guide provides multiple methods to completely clean up all deployed AWS resources to avoid charges and resource limits in your AWS Academy Sandbox environment.

## 🚨 IMPORTANT: Why Cleanup?

### AWS Academy Constraints
- **Resource Limits**: Sandbox has strict limits on running instances
- **Session Expiry**: Resources persist after lab session ends
- **Cost Awareness**: Avoid unnecessary charges
- **Clean Slate**: Prepare for fresh deployments

### Resources That Will Be Destroyed
- ✅ **CloudFront Distribution** (global CDN)
- ✅ **Application Load Balancer** (ALB)
- ✅ **Auto Scaling Groups** (ASG) and EC2 instances
- ✅ **RDS Aurora Database** (with all data)
- ✅ **S3 Buckets** (with all content)
- ✅ **VPC and Networking** (subnets, gateways, etc.)
- ✅ **CloudWatch Log Groups** and alarms
- ✅ **SNS Topics** and subscriptions
- ✅ **Security Groups** and NACLs

## 🚀 Cleanup Methods

### Method 1: GitHub Actions (Recommended)

#### Via GitHub Web Interface
1. **Go to**: https://github.com/kashedin/automate-endtoend/actions
2. **Select**: "Cleanup Infrastructure" workflow
3. **Click**: "Run workflow"
4. **Configure**:
   - **Environment**: `dev`, `prod`, or `both`
   - **Confirm destruction**: Type `DESTROY`
   - **Force cleanup**: Check if you want to skip destroy plan
5. **Click**: "Run workflow"

#### Via GitHub CLI
```bash
# Cleanup dev environment
gh workflow run "Cleanup Infrastructure" \\
  --field environment=dev \\
  --field confirm_destruction=DESTROY

# Cleanup both environments with force
gh workflow run "Cleanup Infrastructure" \\
  --field environment=both \\
  --field confirm_destruction=DESTROY \\
  --field force_cleanup=true
```

### Method 2: PowerShell Script (Windows)

```powershell
# Basic cleanup (both environments with confirmations)
.\\scripts\\cleanup-all-resources.ps1

# Cleanup specific environment
.\\scripts\\cleanup-all-resources.ps1 -Environment dev

# Force cleanup without confirmations
.\\scripts\\cleanup-all-resources.ps1 -Environment both -Force -SkipConfirmation
```

#### PowerShell Script Options
- `-Environment`: `dev`, `prod`, or `both`
- `-Force`: Skip destroy plan, immediate destruction
- `-SkipConfirmation`: Skip all confirmation prompts

### Method 3: Bash Script (Linux/macOS)

```bash
# Make script executable (if needed)
chmod +x scripts/cleanup-all-resources.sh

# Basic cleanup
./scripts/cleanup-all-resources.sh

# Cleanup specific environment
./scripts/cleanup-all-resources.sh --environment dev

# Force cleanup without confirmations
./scripts/cleanup-all-resources.sh --environment both --force --yes
```

#### Bash Script Options
- `-e, --environment`: `dev`, `prod`, or `both`
- `-f, --force`: Skip destroy plan, immediate destruction
- `-y, --yes`: Skip all confirmation prompts
- `-h, --help`: Show help message

### Method 4: Manual Terraform (Advanced)

#### For Dev Environment
```bash
cd terraform/environments/dev
terraform init
terraform destroy
```

#### For Prod Environment
```bash
cd terraform/environments/prod
terraform init
terraform destroy
```

## 🔍 Verification Steps

### 1. Check AWS Console
After cleanup, verify in AWS Console:
- **EC2**: No running instances
- **RDS**: No database instances
- **S3**: No project-related buckets
- **CloudFront**: No distributions (may show "Disabled")
- **VPC**: Default VPC only

### 2. Check for Orphaned Resources
```bash
# List EC2 instances
aws ec2 describe-instances --query 'Reservations[*].Instances[?State.Name!=`terminated`]'

# List S3 buckets
aws s3 ls | grep -E "(dev-|prod-)"

# List CloudFront distributions
aws cloudfront list-distributions --query 'DistributionList.Items[].{Id:Id,Comment:Comment,Status:Status}'

# List RDS instances
aws rds describe-db-instances --query 'DBInstances[].DBInstanceIdentifier'
```

## ⚠️ Troubleshooting

### Common Issues

#### 1. "Resource has dependent objects"
**Solution**: Some resources have dependencies. The scripts handle this automatically, but manual cleanup may require specific order.

#### 2. "CloudFront distribution cannot be deleted"
**Cause**: CloudFront distributions must be disabled before deletion
**Solution**: Wait 15-20 minutes, then retry. The scripts handle this automatically.

#### 3. "S3 bucket not empty"
**Cause**: Bucket contains objects or versions
**Solution**: Scripts use `--force` flag to empty buckets first

#### 4. "Terraform state lock"
**Cause**: Another operation is in progress
**Solution**: Wait a few minutes and retry, or check for stuck processes

### Manual Resource Cleanup

If automated cleanup fails, manually delete in this order:

1. **CloudFront Distributions**
   ```bash
   # Disable first, then delete after 15-20 minutes
   aws cloudfront get-distribution-config --id DISTRIBUTION_ID
   # Update to disabled, then delete
   ```

2. **S3 Buckets**
   ```bash
   # Empty and delete
   aws s3 rb s3://bucket-name --force
   ```

3. **EC2 Resources**
   ```bash
   # Terminate instances
   aws ec2 terminate-instances --instance-ids i-1234567890abcdef0
   
   # Delete Auto Scaling Groups
   aws autoscaling delete-auto-scaling-group --auto-scaling-group-name name --force-delete
   ```

4. **RDS Resources**
   ```bash
   # Delete database (skip final snapshot for cleanup)
   aws rds delete-db-instance --db-instance-identifier mydb --skip-final-snapshot
   ```

5. **VPC Resources**
   ```bash
   # Delete in order: instances → subnets → route tables → gateways → VPC
   ```

## 📊 Cleanup Verification Checklist

After running cleanup, verify:

- [ ] No EC2 instances running
- [ ] No RDS databases exist
- [ ] No S3 buckets with project prefixes
- [ ] No CloudFront distributions (or all disabled)
- [ ] No custom VPCs (only default VPC)
- [ ] No Auto Scaling Groups
- [ ] No Application Load Balancers
- [ ] No CloudWatch alarms firing
- [ ] No SNS topics with project names

## 🎯 Success Indicators

### Cleanup Successful When:
- ✅ All scripts report "SUCCESS"
- ✅ AWS Console shows no project resources
- ✅ No ongoing charges in AWS billing
- ✅ Resource limits reset for new deployments

### Ready for Next Deployment When:
- ✅ AWS Academy lab session is active
- ✅ Fresh credentials obtained
- ✅ GitHub secrets updated
- ✅ No resource conflicts exist

## 🆘 Emergency Cleanup

If you need immediate cleanup (e.g., approaching resource limits):

```bash
# PowerShell (Windows)
.\\scripts\\cleanup-all-resources.ps1 -Environment both -Force -SkipConfirmation

# Bash (Linux/macOS)
./scripts/cleanup-all-resources.sh --environment both --force --yes
```

## 📞 Support

If cleanup fails:
1. Check the script output for specific error messages
2. Verify AWS credentials are valid and not expired
3. Check AWS Console for resource states
4. Try manual cleanup for stuck resources
5. Restart AWS Academy lab session if needed

## 🎉 After Successful Cleanup

Your AWS environment is now clean and ready for:
- ✅ Fresh infrastructure deployments
- ✅ New AWS Academy lab sessions
- ✅ Experimentation without resource conflicts
- ✅ Cost-effective learning environment

---

**Remember**: Always cleanup resources when done to maintain a clean, cost-effective learning environment! 🌟