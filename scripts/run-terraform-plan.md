# Run Terraform Plan Test

## Quick Test Steps

### Option 1: Via GitHub Actions UI
1. Go to: https://github.com/kashedin/automate-endtoend/actions
2. Click "Terraform Plan" workflow
3. Click "Run workflow" button
4. Select environment: `development`
5. Click "Run workflow"

### Option 2: Via GitHub CLI (after authentication)
```bash
gh workflow run terraform-plan.yml -f environment=development
```

## Expected Results

The workflow should:
- ✅ Initialize Terraform with your backend
- ✅ Validate all Terraform configurations
- ✅ Generate a plan showing resources to be created
- ✅ Display plan summary in workflow logs

## Resources That Will Be Planned

Your plan should show these resources to be created:

### Networking (terraform/modules/networking/)
- VPC with CIDR 10.0.0.0/16
- 2 Public subnets (10.0.1.0/24, 10.0.2.0/24)
- 2 Private subnets (10.0.3.0/24, 10.0.4.0/24)
- Internet Gateway
- NAT Gateways
- Route tables and associations

### Security (terraform/modules/security/)
- Security group for web tier (ports 80, 443)
- Security group for app tier (port 8080)
- Security group for database tier (port 3306)

### Database (terraform/modules/database/)
- RDS Aurora MySQL cluster
- Aurora cluster instances
- DB subnet group
- Parameter groups

### Compute (terraform/modules/compute/)
- Launch template for web servers
- Launch template for app servers
- Auto Scaling Groups
- Application Load Balancer
- Target groups

### Storage (terraform/modules/storage/)
- S3 bucket for static content
- Bucket policies and configurations

### Monitoring (terraform/modules/monitoring/)
- CloudWatch alarms
- SNS topics for notifications
- CloudWatch log groups

## Troubleshooting

If the plan fails:

1. **Check backend access**: Verify S3 bucket and DynamoDB table exist
2. **Verify secrets**: Ensure all GitHub secrets are properly configured
3. **Check permissions**: Verify AWS credentials have necessary permissions
4. **Review logs**: Check GitHub Actions logs for specific error messages

## Next Steps

After successful plan:
1. Review the planned resources
2. Verify resource counts and configurations
3. Proceed to Terraform Apply if plan looks correct