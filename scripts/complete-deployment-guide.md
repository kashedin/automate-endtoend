# 🚀 Complete Deployment Guide for Automated Cloud Infrastructure

## Overview

This guide will walk you through the complete deployment process from setting up GitHub secrets to deploying your infrastructure on AWS.

## Prerequisites

- ✅ AWS credentials (provided)
- ✅ GitHub account
- ✅ Git repository initialized locally

## Phase 1: GitHub Repository Setup

### Step 1: Create GitHub Repository

1. Go to [GitHub.com](https://github.com) and sign in
2. Click **"+"** → **"New repository"**
3. Repository settings:
   - **Name**: `automated-cloud-infrastructure`
   - **Description**: `Automated end-to-end cloud infrastructure deployment using Terraform and CI/CD`
   - **Visibility**: Private (recommended)
   - **Initialize**: Don't check any boxes (we have existing code)
4. Click **"Create repository"**

### Step 2: Add GitHub Secrets

Go to your repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these secrets exactly as shown:

| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | `ASIA5HZH53W7BLJHJEME` |
| `AWS_SECRET_ACCESS_KEY` | `KH2VLH8LOLtqqtv0Pe1y9w/i0ONFqsXI9Pq16eE0` |
| `AWS_SESSION_TOKEN` | `IQoJb3JpZ2luX2VjEKj//////////wEaCXVzLXdlc3QtMiJIMEYCIQDaZCTXPt9XMR1jX0htDdX9G0SFlxypNbHO62coD1l1owIhAJtqi4MYPaEvDdL/uAwahX2ZcLbDn6iPcMEmGfpEPX3QKq0CCNH//////////wEQARoMOTEwMDc5OTQyMDc4IgwM0Z19ZiXx1G0BApoqgQJSMxMz5fR42hBTKoN2AQnH5aIfzzlgiq0YIMAXssdtEDYAAz4tBIVw+DGiDie2RH2EMoPAaE+bv9bjrKIOszFLvMydrCubFZp0T8vv83egRQlZ8Hrjuhga+kSBkwR0QY5mOthiEeI1JZ05u79OJS44TL05AnCdrS30M6JQlyo6HBZR6HKL88ShZc6+0iYz63UIL/71Ee/ndmowE5M8fP34AcN+i9NL/nU40nTdgkNh+H5EEoVzp2y06cVQS/SX1heQNOVE55QrgvaXg5Ge5aQOKpijqfPanL7u2kTY/HPGF5cTZ38io39JcSkTiAydeUfcZ+/xCVOfBZL6w08UxJT+xTC3wKzEBjqcAWUcsz4QcIoRKXUr//hbvcm7nZEVg9hIa23z38pm0kw4KyvCUzSylLfTPk4x+KLjOs0tuIYfX80xqUFtKjXo88DpMogcgZXxJ3rQR/OQpMwOK6zovz8J6p+dcY0Dyd5b+O9zZGzpzsC82vPffdQdO6emBKbSob+a6CIKCIHcootx5qPE49wfKGLAiAx+STrbPBAAeMYiu5qqKrJl/w==` |
| `AWS_DEFAULT_REGION` | `us-east-1` |
| `TF_STATE_BUCKET` | `terraform-state-kashedin-$(date +%s)` |
| `TF_STATE_DYNAMODB_TABLE` | `terraform-state-lock-kashedin` |

**Important**: For `TF_STATE_BUCKET`, replace `$(date +%s)` with a unique number (like current timestamp: 1704067200)

### Step 3: Push Code to GitHub

```bash
# Add GitHub remote (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/automated-cloud-infrastructure.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## Phase 2: Test AWS Credentials

### Step 1: Run AWS Credentials Test

1. Go to your GitHub repository
2. Click **Actions** tab
3. Find **"Test AWS Access"** workflow
4. Click **"Run workflow"** → **"Run workflow"**
5. Wait for completion (should show green checkmark)

If the test fails:
- Double-check all secrets are added correctly
- Verify no extra spaces in secret values
- Ensure session token is complete

## Phase 3: Set Up Terraform Backend

Before deploying the main infrastructure, we need to create the S3 bucket and DynamoDB table for Terraform state management.

### Option A: Using Local Terraform (Recommended)

If you have Terraform installed locally:

```bash
# Navigate to backend setup
cd terraform/backend-setup

# Set environment variables
export AWS_ACCESS_KEY_ID="ASIA5HZH53W7BLJHJEME"
export AWS_SECRET_ACCESS_KEY="KH2VLH8LOLtqqtv0Pe1y9w/i0ONFqsXI9Pq16eE0"
export AWS_SESSION_TOKEN="IQoJb3JpZ2luX2VjEKj//////////wEaCXVzLXdlc3QtMiJIMEYCIQDaZCTXPt9XMR1jX0htDdX9G0SFlxypNbHO62coD1l1owIhAJtqi4MYPaEvDdL/uAwahX2ZcLbDn6iPcMEmGfpEPX3QKq0CCNH//////////wEQARoMOTEwMDc5OTQyMDc4IgwM0Z19ZiXx1G0BApoqgQJSMxMz5fR42hBTKoN2AQnH5aIfzzlgiq0YIMAXssdtEDYAAz4tBIVw+DGiDie2RH2EMoPAaE+bv9bjrKIOszFLvMydrCubFZp0T8vv83egRQlZ8Hrjuhga+kSBkwR0QY5mOthiEeI1JZ05u79OJS44TL05AnCdrS30M6JQlyo6HBZR6HKL88ShZc6+0iYz63UIL/71Ee/ndmowE5M8fP34AcN+i9NL/nU40nTdgkNh+H5EEoVzp2y06cVQS/SX1heQNOVE55QrgvaXg5Ge5aQOKpijqfPanL7u2kTY/HPGF5cTZ38io39JcSkTiAydeUfcZ+/xCVOfBZL6w08UxJT+xTC3wKzEBjqcAWUcsz4QcIoRKXUr//hbvcm7nZEVg9hIa23z38pm0kw4KyvCUzSylLfTPk4x+KLjOs0tuIYfX80xqUFtKjXo88DpMogcgZXxJ3rQR/OQpMwOK6zovz8J6p+dcY0Dyd5b+O9zZGzpzsC82vPffdQdO6emBKbSob+a6CIKCIHcootx5qPE49wfKGLAiAx+STrbPBAAeMYiu5qqKrJl/w=="
export AWS_DEFAULT_REGION="us-east-1"

# Initialize and apply
terraform init
terraform plan
terraform apply -auto-approve

# Note the outputs - you'll need the bucket name for GitHub secrets
terraform output
```

### Option B: Manual AWS Console Setup

If you don't have Terraform locally:

1. **Create S3 Bucket**:
   - Go to AWS S3 Console
   - Create bucket: `terraform-state-kashedin-$(unique-number)`
   - Enable versioning
   - Keep default settings

2. **Create DynamoDB Table**:
   - Go to AWS DynamoDB Console
   - Create table: `terraform-state-lock-kashedin`
   - Partition key: `LockID` (String)
   - Use on-demand billing

3. **Update GitHub Secret**:
   - Update `TF_STATE_BUCKET` secret with actual bucket name

## Phase 4: Configure Repository Settings

### Step 1: Set Up Branch Protection

1. Go to **Settings** → **Branches**
2. Click **"Add rule"**
3. Branch name pattern: `main`
4. Enable these protections:
   - ✅ Require a pull request before merging
   - ✅ Require approvals (1)
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
   - ✅ Include administrators
5. Click **"Create"**

### Step 2: Create Environments

1. Go to **Settings** → **Environments**
2. Create `development` environment:
   - No protection rules
   - Deployment branches: All branches
3. Create `production` environment:
   - Required reviewers: Add yourself
   - Wait timer: 5 minutes
   - Deployment branches: Selected branches → `main`

## Phase 5: Deploy Infrastructure

### Step 1: Development Environment

1. Create a new branch:
   ```bash
   git checkout -b deploy-dev
   git push origin deploy-dev
   ```

2. Create a Pull Request:
   - Go to GitHub → **Pull requests** → **New pull request**
   - Base: `main` ← Compare: `deploy-dev`
   - Title: "Deploy development infrastructure"
   - Create pull request

3. Watch the CI/CD pipeline:
   - **Terraform Validate**: Checks syntax
   - **Terraform Plan**: Shows what will be created
   - Review the plan output in the workflow logs

4. Merge the PR:
   - If all checks pass, merge the pull request
   - This will trigger the deployment to development

### Step 2: Production Environment

After successful development deployment:

1. The merge to `main` will automatically trigger production deployment
2. Due to environment protection rules:
   - You'll receive a notification for approval
   - Wait 5 minutes (wait timer)
   - Approve the deployment
3. Monitor the deployment in **Actions** tab

## Phase 6: Verify Deployment

### Check AWS Resources

After successful deployment, verify these resources exist:

1. **VPC and Networking**:
   - VPC with public/private subnets
   - Internet Gateway and NAT Gateways
   - Route tables configured

2. **Security Groups**:
   - Web tier security group (ports 80, 443)
   - App tier security group (port 8080)
   - Database security group (port 3306)

3. **Database**:
   - Aurora MySQL cluster
   - Database subnet group
   - Parameter group

4. **Compute**:
   - Launch templates for web and app tiers
   - Auto Scaling Groups
   - Application Load Balancer

5. **Storage**:
   - S3 buckets for application data
   - Static website hosting configured

6. **Monitoring**:
   - CloudWatch dashboards
   - SNS topics for alerts
   - CloudWatch alarms

### Test Application Access

1. Find the Load Balancer DNS name:
   - Go to EC2 Console → Load Balancers
   - Copy the DNS name

2. Test web access:
   ```bash
   curl http://YOUR-ALB-DNS-NAME
   ```

3. Check application health:
   - Load balancer should show healthy targets
   - Auto Scaling Groups should have running instances

## Phase 7: Monitor and Maintain

### CloudWatch Dashboards

Access monitoring dashboards:
1. Go to CloudWatch Console
2. Find dashboards created by Terraform
3. Monitor key metrics:
   - EC2 instance health
   - Database performance
   - Load balancer metrics
   - Application response times

### Cost Monitoring

1. Check AWS Cost Explorer for resource costs
2. Review resource tags for cost allocation
3. Monitor S3 storage usage
4. Review RDS instance utilization

### Maintenance Tasks

1. **Regular Updates**:
   - Update Terraform modules
   - Patch EC2 instances
   - Update application code

2. **Security**:
   - Rotate AWS credentials regularly
   - Review security group rules
   - Monitor CloudTrail logs

3. **Backup**:
   - Verify RDS automated backups
   - Test disaster recovery procedures

## Troubleshooting

### Common Issues

#### 1. Terraform State Lock

If deployment fails with state lock error:
```bash
# Force unlock (use carefully)
terraform force-unlock LOCK_ID
```

#### 2. Resource Limits

If hitting AWS service limits:
- Request limit increases in AWS Console
- Or reduce resource counts in terraform.tfvars

#### 3. Permission Errors

If getting permission denied:
- Verify AWS credentials are correct
- Check IAM permissions
- Ensure session token hasn't expired

#### 4. Network Connectivity

If instances can't reach internet:
- Check NAT Gateway configuration
- Verify route table associations
- Check security group rules

### Getting Help

- **AWS Documentation**: https://docs.aws.amazon.com/
- **Terraform Documentation**: https://registry.terraform.io/providers/hashicorp/aws/
- **GitHub Actions**: https://docs.github.com/en/actions

## Success Metrics

Your deployment is successful when:

- ✅ All GitHub Actions workflows complete successfully
- ✅ AWS resources are created and healthy
- ✅ Load balancer returns HTTP 200 responses
- ✅ Database is accessible from application tier
- ✅ Monitoring dashboards show green metrics
- ✅ Auto Scaling Groups maintain desired capacity

## Next Steps

After successful deployment:

1. **Application Deployment**:
   - Deploy your application code to EC2 instances
   - Configure application-specific settings
   - Set up application monitoring

2. **Security Hardening**:
   - Implement WAF rules
   - Set up VPN access
   - Configure additional security monitoring

3. **Performance Optimization**:
   - Tune database parameters
   - Optimize Auto Scaling policies
   - Implement caching strategies

4. **Disaster Recovery**:
   - Set up cross-region backups
   - Document recovery procedures
   - Test failover scenarios

**Congratulations! Your automated cloud infrastructure is now deployed and ready for production use!** 🎉