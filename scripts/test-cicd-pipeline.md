# CI/CD Pipeline Testing Guide

## Overview
This guide helps you test your complete automated cloud infrastructure CI/CD pipeline.

## Prerequisites
- ✅ GitHub secrets configured
- ✅ AWS test workflow successful
- ✅ Backend infrastructure deployed

## Testing Steps

### 1. Test Terraform Validation Workflow

**Trigger**: Automatically runs on pull requests

```bash
# Create a test branch
git checkout -b test-terraform-validation

# Make a small change to test validation
echo "# Test comment" >> terraform/environments/dev/main.tf

# Commit and push
git add .
git commit -m "Test: Add comment to trigger validation"
git push origin test-terraform-validation

# Create pull request via GitHub UI
# Watch the terraform-validate workflow run automatically
```

### 2. Test Terraform Plan Workflow

**Manual Trigger**: Go to Actions → Terraform Plan

1. Navigate to: https://github.com/kashedin/automate-endtoend/actions
2. Click "Terraform Plan" workflow
3. Click "Run workflow"
4. Select environment: `development`
5. Click "Run workflow"

**Expected Output**:
- ✅ Terraform initialization successful
- ✅ Plan shows resources to be created
- ✅ No errors in validation

### 3. Test Infrastructure Deployment

**Manual Trigger**: Go to Actions → Terraform Apply

⚠️ **Warning**: This will create real AWS resources and may incur costs

1. Navigate to: https://github.com/kashedin/automate-endtoend/actions
2. Click "Terraform Apply" workflow
3. Click "Run workflow"
4. Select environment: `development`
5. Click "Run workflow"

**Expected Resources Created**:
- VPC with public/private subnets
- Security groups
- RDS Aurora MySQL cluster
- Auto Scaling Group with EC2 instances
- Application Load Balancer
- S3 bucket for static content
- CloudWatch monitoring and alarms

### 4. Verify Deployed Infrastructure

After successful deployment, verify in AWS Console:

1. **VPC**: Check subnets, route tables, internet gateway
2. **EC2**: Verify instances are running in Auto Scaling Group
3. **RDS**: Confirm Aurora cluster is available
4. **Load Balancer**: Check target group health
5. **S3**: Verify bucket creation and static content
6. **CloudWatch**: Review alarms and metrics

### 5. Test Production Deployment (Optional)

For production deployment:

1. Merge your test branch to `master`
2. Run Terraform Plan for `production` environment
3. Review plan carefully
4. Run Terraform Apply for `production` environment
5. Verify production environment protection rules work

## Troubleshooting

### Common Issues

1. **Terraform Backend Access**
   - Verify S3 bucket and DynamoDB table exist
   - Check AWS credentials have proper permissions

2. **Resource Creation Failures**
   - Review AWS service limits
   - Check IAM permissions for specific services
   - Verify region availability for resources

3. **Workflow Failures**
   - Check GitHub Actions logs
   - Verify all secrets are properly configured
   - Ensure Terraform syntax is valid

### Cleanup Resources

To avoid ongoing costs, destroy resources when testing is complete:

```bash
# Run Terraform Destroy workflow
# Or manually via CLI:
cd terraform/environments/dev
terraform init -backend-config="bucket=terraform-state-kashedin-422bf0c7" \
               -backend-config="key=dev/terraform.tfstate" \
               -backend-config="region=us-west-2" \
               -backend-config="dynamodb_table=terraform-state-lock-kashedin"
terraform destroy
```

## Success Criteria

Your CI/CD pipeline is working correctly when:

- ✅ Pull requests trigger validation automatically
- ✅ Manual plan workflows show expected resources
- ✅ Apply workflows successfully create infrastructure
- ✅ AWS resources are created as specified
- ✅ Monitoring and alerts are functional
- ✅ State is properly stored in S3 backend
- ✅ State locking works via DynamoDB

## Next Steps

After successful testing:

1. Configure branch protection rules
2. Set up production environment protection
3. Add team members as reviewers
4. Implement monitoring and alerting
5. Document operational procedures

Your enterprise-grade DevOps pipeline is now ready for production use! 🚀