# GitHub Repository Setup Guide

## Overview

This guide provides step-by-step instructions for setting up the GitHub repository and configuring secrets for the Automated Cloud Infrastructure CI/CD pipeline.

## Repository Setup

### 1. Create GitHub Repository

1. Go to [GitHub](https://github.com) and sign in to your account
2. Click the "+" icon in the top right corner and select "New repository"
3. Configure the repository:
   - **Repository name**: `automated-cloud-infrastructure`
   - **Description**: `Automated end-to-end cloud infrastructure deployment using Terraform and CI/CD`
   - **Visibility**: Private (recommended for infrastructure code)
   - **Initialize**: Check "Add a README file"
   - **Add .gitignore**: Choose "Terraform" template
   - **Choose a license**: MIT License (optional)

### 2. Clone Repository Locally

```bash
git clone https://github.com/YOUR_USERNAME/automated-cloud-infrastructure.git
cd automated-cloud-infrastructure
```

### 3. Add Project Files

Copy all the project files to your local repository:

```bash
# Copy all terraform files and documentation
cp -r /path/to/project/* .

# Add all files to git
git add .
git commit -m "Initial commit: Add automated cloud infrastructure"
git push origin main
```

## GitHub Secrets Configuration

### Required Secrets

Navigate to your repository → Settings → Secrets and variables → Actions → New repository secret

#### AWS Credentials

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key ID | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_DEFAULT_REGION` | Default AWS region | `us-east-1` |

#### Terraform Backend Configuration

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `TF_STATE_BUCKET` | S3 bucket for Terraform state | `terraform-state-abc123def456` |
| `TF_STATE_DYNAMODB_TABLE` | DynamoDB table for state locking | `terraform-state-lock` |

#### Environment-Specific Secrets

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `DEV_ALERT_EMAILS` | Development alert emails (JSON array) | `[]` |
| `PROD_ALERT_EMAILS` | Production alert emails (JSON array) | `["devops@company.com"]` |

### Optional Secrets

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `SLACK_WEBHOOK_URL` | Slack webhook for notifications | `https://hooks.slack.com/...` |
| `INFRACOST_API_KEY` | Infracost API key for cost estimation | `ico-xxx...` |

## AWS IAM Setup

### 1. Create IAM User for GitHub Actions

Create an IAM user with programmatic access:

```bash
aws iam create-user --user-name github-actions-terraform
```

### 2. Create and Attach Policy

Create a policy with necessary permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "rds:*",
        "s3:*",
        "iam:*",
        "vpc:*",
        "elasticloadbalancing:*",
        "autoscaling:*",
        "cloudwatch:*",
        "logs:*",
        "sns:*",
        "ssm:*",
        "dynamodb:*"
      ],
      "Resource": "*"
    }
  ]
}
```

Attach the policy:

```bash
aws iam put-user-policy \
  --user-name github-actions-terraform \
  --policy-name TerraformFullAccess \
  --policy-document file://terraform-policy.json
```

### 3. Create Access Keys

```bash
aws iam create-access-key --user-name github-actions-terraform
```

Save the Access Key ID and Secret Access Key for GitHub Secrets.

## Repository Settings

### Branch Protection Rules

1. Go to Settings → Branches
2. Click "Add rule"
3. Configure protection for `main` branch:
   - **Branch name pattern**: `main`
   - ✅ Require a pull request before merging
   - ✅ Require approvals (1)
   - ✅ Dismiss stale PR approvals when new commits are pushed
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
   - ✅ Require conversation resolution before merging
   - ✅ Include administrators

### Required Status Checks

Add these status checks (they will appear after first workflow runs):
- `terraform-validate`
- `terraform-plan-dev`
- `terraform-plan-prod`
- `security-scan`

## Environment Setup

### 1. Create GitHub Environments

1. Go to Settings → Environments
2. Create environments:
   - `development`
   - `production`

### 2. Configure Environment Protection Rules

#### Development Environment
- No protection rules needed
- Deployment branches: All branches

#### Production Environment
- ✅ Required reviewers: Add team members
- ✅ Wait timer: 5 minutes
- ✅ Deployment branches: Selected branches → `main`

### 3. Environment Secrets

Add environment-specific secrets if needed:

#### Development Environment
- No additional secrets required

#### Production Environment
- `PROD_APPROVAL_REQUIRED`: `true`
- Additional production-specific configurations

## Workflow Files Structure

The CI/CD pipeline consists of these workflow files:

```
.github/
└── workflows/
    ├── terraform-validate.yml    # Validation on all PRs
    ├── terraform-plan.yml        # Plan on PRs
    ├── terraform-apply.yml       # Apply on main branch
    └── security-scan.yml         # Security scanning
```

## Testing the Setup

### 1. Test Repository Access

```bash
# Clone and test
git clone https://github.com/YOUR_USERNAME/automated-cloud-infrastructure.git
cd automated-cloud-infrastructure
git checkout -b test-branch
echo "# Test" >> README.md
git add README.md
git commit -m "Test commit"
git push origin test-branch
```

### 2. Create Test Pull Request

1. Create a pull request from `test-branch` to `main`
2. Verify that GitHub Actions workflows trigger
3. Check that status checks appear and pass

### 3. Test AWS Credentials

Create a simple test workflow to verify AWS access:

```yaml
name: Test AWS Access
on:
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_DEFAULT_REGION }}
      
      - name: Test AWS CLI
        run: aws sts get-caller-identity
```

## Security Best Practices

### 1. Secrets Management

- ✅ Use GitHub Secrets for sensitive data
- ✅ Never commit credentials to repository
- ✅ Use least privilege IAM policies
- ✅ Rotate access keys regularly
- ✅ Monitor AWS CloudTrail for API usage

### 2. Repository Security

- ✅ Enable branch protection rules
- ✅ Require code reviews
- ✅ Enable security alerts
- ✅ Use private repository for infrastructure code
- ✅ Enable dependency scanning

### 3. Workflow Security

- ✅ Pin action versions to specific commits
- ✅ Use official GitHub Actions when possible
- ✅ Limit workflow permissions
- ✅ Use environment protection rules
- ✅ Enable workflow approval for production

## Troubleshooting

### Common Issues

#### 1. AWS Credentials Not Working

```bash
# Test credentials locally
aws sts get-caller-identity

# Check IAM permissions
aws iam get-user --user-name github-actions-terraform
```

#### 2. Terraform State Access Issues

```bash
# Verify S3 bucket access
aws s3 ls s3://your-terraform-state-bucket

# Check DynamoDB table
aws dynamodb describe-table --table-name terraform-state-lock
```

#### 3. GitHub Actions Not Triggering

- Check workflow file syntax
- Verify branch protection rules
- Check repository permissions
- Review workflow run logs

### Getting Help

- GitHub Actions Documentation: https://docs.github.com/en/actions
- Terraform GitHub Actions: https://github.com/hashicorp/setup-terraform
- AWS CLI Documentation: https://docs.aws.amazon.com/cli/

## Next Steps

After completing the repository setup:

1. ✅ Repository created and configured
2. ✅ Secrets added and tested
3. ✅ Branch protection rules enabled
4. ✅ Environments configured
5. → Proceed to implement GitHub Actions workflows

The repository is now ready for the CI/CD pipeline implementation!