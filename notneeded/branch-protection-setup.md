# Branch Protection Rules Setup

## Overview

This document provides instructions for configuring branch protection rules to ensure code quality and security for the Automated Cloud Infrastructure project.

## Branch Protection Configuration

### 1. Access Branch Protection Settings

1. Navigate to your GitHub repository
2. Go to **Settings** → **Branches**
3. Click **Add rule** or edit existing rule for `main` branch

### 2. Branch Protection Rule Configuration

#### Basic Settings

| Setting | Value | Description |
|---------|-------|-------------|
| **Branch name pattern** | `main` | Protects the main branch |
| **Restrict pushes that create files** | ✅ | Prevents direct pushes |

#### Pull Request Requirements

| Setting | Value | Description |
|---------|-------|-------------|
| **Require a pull request before merging** | ✅ | All changes must go through PR |
| **Required number of reviewers** | `1` | At least one approval required |
| **Dismiss stale PR approvals** | ✅ | Re-approval needed after new commits |
| **Require review from code owners** | ✅ | Code owners must approve |
| **Restrict reviews to users with write access** | ✅ | Only collaborators can approve |

#### Status Check Requirements

| Setting | Value | Description |
|---------|-------|-------------|
| **Require status checks to pass** | ✅ | All checks must pass |
| **Require branches to be up to date** | ✅ | Branch must be current |

**Required Status Checks:**
- `terraform-validate`
- `tflint`
- `checkov`
- `terraform-plan-dev`
- `terraform-plan-prod`

#### Additional Restrictions

| Setting | Value | Description |
|---------|-------|-------------|
| **Require conversation resolution** | ✅ | All comments must be resolved |
| **Require signed commits** | ❌ | Optional for this project |
| **Require linear history** | ✅ | Prevents merge commits |
| **Include administrators** | ✅ | Rules apply to admins too |
| **Allow force pushes** | ❌ | Prevents force pushes |
| **Allow deletions** | ❌ | Prevents branch deletion |

## Code Owners Configuration

### 1. Create CODEOWNERS File

Create `.github/CODEOWNERS` file:

```bash
# Global owners
* @your-username @team-devops

# Terraform infrastructure
terraform/ @your-username @team-devops @team-platform

# GitHub workflows
.github/ @your-username @team-devops

# Documentation
docs/ @your-username @team-devops @team-technical-writers

# Security-sensitive files
terraform/modules/security/ @your-username @team-security
.github/workflows/ @your-username @team-security
```

### 2. Team Configuration

If using GitHub Teams, configure teams in your organization:

1. Go to your GitHub organization
2. Navigate to **Teams**
3. Create teams:
   - `team-devops` - DevOps engineers
   - `team-platform` - Platform engineers
   - `team-security` - Security team
   - `team-technical-writers` - Documentation team

## Workflow Status Checks

### Required Checks Configuration

The following status checks must pass before merging:

#### 1. Terraform Validation
- **Check Name**: `terraform-validate`
- **Description**: Validates Terraform syntax and configuration
- **Required**: ✅

#### 2. TFLint Analysis
- **Check Name**: `tflint`
- **Description**: Lints Terraform code for best practices
- **Required**: ✅

#### 3. Security Scan
- **Check Name**: `checkov`
- **Description**: Scans for security vulnerabilities
- **Required**: ✅

#### 4. Development Plan
- **Check Name**: `terraform-plan-dev`
- **Description**: Generates plan for development environment
- **Required**: ✅

#### 5. Production Plan
- **Check Name**: `terraform-plan-prod`
- **Description**: Generates plan for production environment
- **Required**: ✅

### Optional Checks

These checks provide additional value but are not required:

#### 1. Cost Estimation
- **Check Name**: `cost-estimation`
- **Description**: Estimates infrastructure costs
- **Required**: ❌

#### 2. Documentation Generation
- **Check Name**: `terraform-docs`
- **Description**: Updates module documentation
- **Required**: ❌

## Environment Protection Rules

### Development Environment

1. Go to **Settings** → **Environments**
2. Click **New environment** or edit `development`
3. Configure:
   - **Environment name**: `development`
   - **Deployment branches**: All branches
   - **Required reviewers**: None
   - **Wait timer**: 0 minutes

### Production Environment

1. Configure production environment:
   - **Environment name**: `production`
   - **Deployment branches**: Selected branches → `main`
   - **Required reviewers**: Add team members (minimum 1)
   - **Wait timer**: 5 minutes
   - **Prevent self-review**: ✅

## Automated Branch Protection Setup

### Using GitHub CLI

```bash
# Install GitHub CLI if not already installed
# https://cli.github.com/

# Set up branch protection rule
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["terraform-validate","tflint","checkov","terraform-plan-dev","terraform-plan-prod"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true,"require_code_owner_reviews":true,"restrict_reviews_to_users_with_write_access":true}' \
  --field restrictions=null
```

### Using Terraform (GitHub Provider)

```hcl
resource "github_branch_protection" "main" {
  repository_id = github_repository.repo.node_id
  pattern       = "main"

  required_status_checks {
    strict = true
    contexts = [
      "terraform-validate",
      "tflint",
      "checkov",
      "terraform-plan-dev",
      "terraform-plan-prod"
    ]
  }

  required_pull_request_reviews {
    required_approving_review_count = 1
    dismiss_stale_reviews          = true
    require_code_owner_reviews     = true
    restrict_reviews_to_users_with_write_access = true
  }

  enforce_admins = true

  allows_deletions    = false
  allows_force_pushes = false
  require_conversation_resolution = true
}
```

## Verification Steps

### 1. Test Branch Protection

1. Create a test branch:
   ```bash
   git checkout -b test-branch-protection
   echo "# Test" >> test-file.md
   git add test-file.md
   git commit -m "Test branch protection"
   git push origin test-branch-protection
   ```

2. Create a pull request
3. Verify that:
   - Direct push to main is blocked
   - Status checks are required
   - Review is required
   - All configured checks appear

### 2. Test Status Checks

1. Make a change to Terraform code
2. Create a pull request
3. Verify all status checks run:
   - ✅ terraform-validate
   - ✅ tflint
   - ✅ checkov
   - ✅ terraform-plan-dev
   - ✅ terraform-plan-prod

### 3. Test Review Process

1. Request review from code owner
2. Verify review is required before merge
3. Test that stale reviews are dismissed on new commits

## Troubleshooting

### Common Issues

#### 1. Status Checks Not Appearing

**Problem**: Required status checks don't appear in PR
**Solution**: 
- Ensure workflow files are in `.github/workflows/`
- Check workflow syntax with GitHub Actions validator
- Verify workflows run on `pull_request` events

#### 2. Code Owners Not Working

**Problem**: Code owner reviews not required
**Solution**:
- Verify `.github/CODEOWNERS` file exists
- Check file syntax and paths
- Ensure code owners have repository access

#### 3. Branch Protection Not Enforced

**Problem**: Users can still push directly to main
**Solution**:
- Verify branch protection rule is active
- Check that "Include administrators" is enabled
- Ensure rule pattern matches branch name exactly

### Getting Help

- GitHub Branch Protection Documentation: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/about-protected-branches
- GitHub Code Owners Documentation: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
- GitHub Environments Documentation: https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment

## Security Considerations

### 1. Secrets Protection

- Never commit secrets to repository
- Use GitHub Secrets for sensitive data
- Rotate secrets regularly
- Monitor secret usage in audit logs

### 2. Access Control

- Use principle of least privilege
- Regularly review repository access
- Use teams for group permissions
- Enable two-factor authentication

### 3. Audit and Monitoring

- Enable security alerts
- Monitor branch protection changes
- Review access logs regularly
- Set up notifications for security events

## Conclusion

Proper branch protection rules ensure:

- ✅ Code quality through required reviews
- ✅ Security through automated scanning
- ✅ Reliability through comprehensive testing
- ✅ Compliance through enforced processes
- ✅ Collaboration through structured workflows

These rules protect your infrastructure code and ensure that all changes go through proper validation before being deployed to production environments.