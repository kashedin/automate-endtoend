# 🚀 GitHub Manual Deployment Guide - CloudFront CDN Infrastructure

## Overview
This guide shows you how to manually deploy your AWS Academy Sandbox-compliant CloudFront CDN infrastructure using the GitHub web interface.

## Prerequisites

### 1. AWS Academy Lab Setup
- ✅ Start your AWS Academy Lab
- ✅ Click "AWS Details" → "AWS CLI" to get credentials
- ✅ Copy the credentials (they look like this):
```
[default]
aws_access_key_id=ASIA...
aws_secret_access_key=...
aws_session_token=...
```

### 2. GitHub Secrets Configuration
You need to add these secrets to your GitHub repository first.

## 🔧 Step 1: Configure GitHub Secrets

### Navigate to Secrets Settings
1. Go to your repository: https://github.com/kashedin/automate-endtoend
2. Click **"Settings"** tab (top right)
3. In the left sidebar, click **"Secrets and variables"** → **"Actions"**

### Add Required Secrets
Click **"New repository secret"** for each of these:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AWS_ACCESS_KEY_ID` | `ASIA...` | Your AWS Access Key ID from Academy |
| `AWS_SECRET_ACCESS_KEY` | `...` | Your AWS Secret Access Key from Academy |
| `AWS_SESSION_TOKEN` | `...` | Your AWS Session Token from Academy |
| `AWS_DEFAULT_REGION` | `us-west-2` | AWS Region for deployment |

**⚠️ Important**: AWS Academy credentials expire when your lab session ends. You'll need to update these secrets each time you start a new lab session.

## 🚀 Step 2: Manual Deployment via GitHub Web Interface

### Option A: Deploy Complete 3-Tier Architecture with CloudFront

#### Navigate to Actions
1. Go to https://github.com/kashedin/automate-endtoend/actions
2. You'll see a list of workflows on the left sidebar

#### Select Deployment Workflow
1. Click **"Deploy 3-Tier Architecture"** in the left sidebar
2. You'll see the workflow runs history

#### Trigger Manual Deployment
1. Click the **"Run workflow"** button (top right, blue button)
2. A dropdown will appear with these options:

**Deployment Configuration:**
- **Use workflow from**: `Branch: master` (keep default)
- **Environment to deploy**: 
  - Select `dev` for development environment
  - Select `prod` for production environment
- **Action to perform**:
  - Select `deploy` to create infrastructure
  - Select `destroy` to remove infrastructure

#### Example Deployment
For your first deployment, use:
- **Environment**: `dev`
- **Action**: `deploy`

3. Click **"Run workflow"** (green button)

### Option B: Deploy CloudFront Enhancement Only

#### Select CloudFront Workflow
1. Go to https://github.com/kashedin/automate-endtoend/actions
2. Click **"Deploy CloudFront Enhancement"** in the left sidebar
3. Click **"Run workflow"** button

**Configuration Options:**
- **Environment to deploy to**: `dev` or `prod`
- **Terraform action to perform**: 
  - `plan` - Show what will be created
  - `apply` - Deploy the infrastructure
  - `destroy` - Remove the infrastructure

#### Example CloudFront Deployment
For CloudFront-only deployment:
- **Environment**: `dev`
- **Terraform action**: `apply`

## 📊 Step 3: Monitor Deployment Progress

### View Running Workflow
1. After clicking "Run workflow", you'll see a new workflow run appear
2. Click on the workflow run to see detailed progress
3. You'll see multiple jobs running:
   - **Deploy 3-Tier Infrastructure** (for complete deployment)
   - **deploy-cloudfront** (for CloudFront-only deployment)

### Monitor Job Progress
1. Click on the job name to see detailed logs
2. Watch the progress through these stages:
   - ✅ Checkout code
   - ✅ Configure AWS credentials
   - ✅ Setup Terraform
   - ✅ Terraform Init
   - ✅ Terraform Validate
   - ✅ Terraform Plan
   - ✅ Terraform Apply
   - ✅ Output URLs and summary

### Deployment Success Indicators
Look for these success messages:
- ✅ **"Terraform Apply"** step shows green checkmark
- ✅ **"Deployment Summary"** shows infrastructure URLs
- ✅ **"Output CloudFront URL"** provides access links

## 🌐 Step 4: Access Your Deployed Infrastructure

### After Successful Deployment
The workflow will provide you with these URLs:

#### Complete 3-Tier Deployment
- **CloudFront HTTPS URL**: `https://d1234567890.cloudfront.net`
- **Application Load Balancer**: `http://dev-alb-12345.us-west-2.elb.amazonaws.com`
- **S3 Static Website**: `http://dev-static-website-12345.s3-website-us-west-2.amazonaws.com`

#### CloudFront-Only Deployment
- **CloudFront HTTPS URL**: `https://d1234567890.cloudfront.net`
- **ALB HTTP URL**: Direct ALB access
- **S3 Static Website**: Failover origin

### Test Your Deployment
```bash
# Test HTTPS access (should work)
curl -I https://your-cloudfront-domain

# Test HTTP redirect (should redirect to HTTPS)
curl -I http://your-cloudfront-domain

# Test failover (when ALB is down, serves from S3)
```

## 🔍 Step 5: Troubleshooting Common Issues

### Issue 1: AWS Credentials Error
**Error**: "The security token included in the request is invalid"
**Solution**: 
1. Check if your AWS Academy lab is still active
2. Get fresh credentials from AWS Academy
3. Update GitHub secrets with new credentials
4. Re-run the workflow

### Issue 2: Resource Limits
**Error**: "LimitExceededException" or "Resource limit exceeded"
**Solution**:
1. Check AWS Academy resource limits
2. Use `dev` environment (smaller instances)
3. Ensure previous resources are cleaned up

### Issue 3: Terraform State Issues
**Error**: "Resource already exists" or state conflicts
**Solution**:
1. Run with `destroy` action first
2. Wait for complete cleanup
3. Re-run with `deploy` action

## 📋 Step 6: Deployment Verification Checklist

### Infrastructure Verification
- [ ] CloudFront distribution is active
- [ ] HTTPS access works through CloudFront
- [ ] HTTP redirects to HTTPS
- [ ] ALB is healthy and responding
- [ ] S3 static website is accessible
- [ ] Auto Scaling Groups are running
- [ ] RDS database is available
- [ ] Security groups are properly configured

### CloudFront Features Verification
- [ ] Global edge locations active
- [ ] Origin failover working (ALB → S3)
- [ ] Security headers present (HSTS, CSP, etc.)
- [ ] Caching working properly
- [ ] Custom error pages displaying
- [ ] Origin Access Control (OAC) securing S3

## 🗑️ Step 7: Cleanup (When Done)

### Destroy Infrastructure
1. Go to GitHub Actions
2. Select your deployment workflow
3. Click "Run workflow"
4. Choose:
   - **Environment**: Same as deployment (`dev` or `prod`)
   - **Action**: `destroy`
5. Click "Run workflow"

### Verify Cleanup
- Check AWS Console to ensure resources are removed
- Verify no ongoing charges in AWS Academy

## 📞 Quick Reference

### GitHub Actions URLs
- **Repository Actions**: https://github.com/kashedin/automate-endtoend/actions
- **Secrets Settings**: https://github.com/kashedin/automate-endtoend/settings/secrets/actions

### Workflow Names
- **Complete Infrastructure**: "Deploy 3-Tier Architecture"
- **CloudFront Only**: "Deploy CloudFront Enhancement"
- **Validation**: "Terraform Validation"

### Common Configurations
| Use Case | Environment | Action |
|----------|-------------|--------|
| First deployment | `dev` | `deploy` |
| Production deployment | `prod` | `deploy` |
| Test changes | `dev` | `plan` |
| Cleanup | `dev`/`prod` | `destroy` |

## 🎯 Success Criteria

Your deployment is successful when:
- ✅ GitHub Actions workflow shows green checkmarks
- ✅ CloudFront URL returns your application over HTTPS
- ✅ HTTP requests redirect to HTTPS
- ✅ Failover works when ALB is unavailable
- ✅ All security headers are present
- ✅ Performance is optimized through edge caching

## 🎉 Congratulations!

You've successfully deployed a production-ready, AWS Academy Sandbox-compliant CloudFront CDN infrastructure using GitHub Actions! Your application now benefits from:

- **Global Performance**: CloudFront edge locations worldwide
- **Enterprise Security**: HTTPS-only with security headers
- **High Availability**: Automatic failover capabilities
- **Cost Optimization**: Sandbox-friendly resource sizing
- **Best Practices**: Infrastructure as Code with CI/CD

**Enjoy your globally distributed, secure, and scalable infrastructure!** 🚀