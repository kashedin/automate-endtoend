# 🚀 GitHub Secrets Setup Guide

## Your AWS Credentials

Based on the credentials you provided, here are the exact values you need to add to your GitHub repository:

### 📋 Required GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these secrets one by one:

#### 1. AWS_ACCESS_KEY_ID
```
ASIA5HZH53W7BLJHJEME
```

#### 2. AWS_SECRET_ACCESS_KEY
```
KH2VLH8LOLtqqtv0Pe1y9w/i0ONFqsXI9Pq16eE0
```

#### 3. AWS_SESSION_TOKEN
```
IQoJb3JpZ2luX2VjEKj//////////wEaCXVzLXdlc3QtMiJIMEYCIQDaZCTXPt9XMR1jX0htDdX9G0SFlxypNbHO62coD1l1owIhAJtqi4MYPaEvDdL/uAwahX2ZcLbDn6iPcMEmGfpEPX3QKq0CCNH//////////wEQARoMOTEwMDc5OTQyMDc4IgwM0Z19ZiXx1G0BApoqgQJSMxMz5fR42hBTKoN2AQnH5aIfzzlgiq0YIMAXssdtEDYAAz4tBIVw+DGiDie2RH2EMoPAaE+bv9bjrKIOszFLvMydrCubFZp0T8vv83egRQlZ8Hrjuhga+kSBkwR0QY5mOthiEeI1JZ05u79OJS44TL05AnCdrS30M6JQlyo6HBZR6HKL88ShZc6+0iYz63UIL/71Ee/ndmowE5M8fP34AcN+i9NL/nU40nTdgkNh+H5EEoVzp2y06cVQS/SX1heQNOVE55QrgvaXg5Ge5aQOKpijqfPanL7u2kTY/HPGF5cTZ38io39JcSkTiAydeUfcZ+/xCVOfBZL6w08UxJT+xTC3wKzEBjqcAWUcsz4QcIoRKXUr//hbvcm7nZEVg9hIa23z38pm0kw4KyvCUzSylLfTPk4x+KLjOs0tuIYfX80xqUFtKjXo88DpMogcgZXxJ3rQR/OQpMwOK6zovz8J6p+dcY0Dyd5b+O9zZGzpzsC82vPffdQdO6emBKbSob+a6CIKCIHcootx5qPE49wfKGLAiAx+STrbPBAAeMYiu5qqKrJl/w==
```

#### 4. AWS_DEFAULT_REGION
```
us-east-1
```

#### 5. TF_STATE_BUCKET
```
terraform-state-automated-infra-$(date +%s)
```
*Note: Replace $(date +%s) with a unique number like your timestamp*

#### 6. TF_STATE_DYNAMODB_TABLE
```
terraform-state-lock
```

## 🔧 Step-by-Step GitHub Setup

### Step 1: Create GitHub Repository (if not done)

1. Go to [GitHub.com](https://github.com)
2. Click **"+"** → **"New repository"**
3. Repository name: `automated-cloud-infrastructure`
4. Set to **Private** (recommended for infrastructure)
5. Click **"Create repository"**

### Step 2: Add Secrets to GitHub

1. Go to your repository
2. Click **Settings** tab
3. In left sidebar, click **Secrets and variables** → **Actions**
4. Click **"New repository secret"**
5. Add each secret from the list above:
   - Name: `AWS_ACCESS_KEY_ID`
   - Secret: `ASIA5HZH53W7BLJHJEME`
   - Click **"Add secret"**
6. Repeat for all 6 secrets

### Step 3: Push Your Code to GitHub

```bash
# Add GitHub remote (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/automated-cloud-infrastructure.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### Step 4: Set Up Branch Protection

1. Go to **Settings** → **Branches**
2. Click **"Add rule"**
3. Branch name pattern: `main`
4. Check these options:
   - ✅ Require a pull request before merging
   - ✅ Require approvals (1)
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
5. Click **"Create"**

### Step 5: Create Environments

1. Go to **Settings** → **Environments**
2. Click **"New environment"**
3. Create two environments:
   - `development`
   - `production`

For production environment:
- Add **Required reviewers** (yourself)
- Set **Wait timer**: 5 minutes
- **Deployment branches**: Selected branches → `main`

## 🧪 Test Your Setup

### Create a Test Workflow

Create `.github/workflows/test-aws-access.yml`:

```yaml
name: Test AWS Access
on:
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-session-token: ${{ secrets.AWS_SESSION_TOKEN }}
          aws-region: ${{ secrets.AWS_DEFAULT_REGION }}
      
      - name: Test AWS CLI
        run: |
          aws sts get-caller-identity
          echo "✅ AWS credentials are working!"
```

### Run the Test

1. Go to **Actions** tab in your repository
2. Click **"Test AWS Access"** workflow
3. Click **"Run workflow"**
4. Check if it passes

## 🚀 Deploy Infrastructure

Once secrets are set up and tested:

### Option 1: Automatic Deployment
1. Push code to `main` branch
2. GitHub Actions will automatically run terraform apply

### Option 2: Manual Deployment
1. Go to **Actions** tab
2. Find **"Terraform Apply"** workflow
3. Click **"Run workflow"**
4. Select environment (`development` or `production`)

## 📊 Monitor Deployment

### Check Workflow Status
- Go to **Actions** tab
- Monitor running workflows
- Check logs for any errors

### Verify AWS Resources
After successful deployment, check AWS Console:
- **VPC**: New VPC with subnets created
- **RDS**: Aurora MySQL cluster running
- **EC2**: Auto Scaling Groups with instances
- **Load Balancer**: Application Load Balancer configured
- **S3**: Buckets for storage and static content

## 🔍 Troubleshooting

### Common Issues

#### 1. AWS Credentials Invalid
- Check if credentials are copied correctly
- Verify no extra spaces or characters
- Ensure session token is included

#### 2. Terraform State Bucket Not Found
- Create S3 bucket manually first
- Or run backend setup: `cd terraform/backend-setup && terraform apply`

#### 3. Permissions Denied
- Verify IAM user has necessary permissions
- Check if temporary credentials have expired

#### 4. Workflow Not Triggering
- Check branch protection rules
- Verify workflow file syntax
- Ensure secrets are added correctly

## 📚 Next Steps

After successful setup:

1. ✅ **Secrets configured**
2. ✅ **Repository set up**
3. ✅ **Branch protection enabled**
4. ✅ **Environments created**
5. → **Deploy infrastructure**
6. → **Test applications**
7. → **Monitor and optimize**

## 🎯 Success Indicators

You'll know everything is working when:
- ✅ GitHub Actions workflows run without errors
- ✅ AWS resources are created successfully
- ✅ Applications are accessible via Load Balancer
- ✅ Monitoring dashboards show healthy metrics

**Your automated cloud infrastructure is ready to deploy!** 🚀