# GitHub Repository Settings Configuration

## Branch Protection Rules

### 1. Navigate to Branch Protection
1. Go to your repository: https://github.com/kashedin/automate-endtoend
2. Click **Settings** → **Branches**
3. Click **Add rule**

### 2. Configure Main Branch Protection

**Branch name pattern**: `master` (or `main` if you switch)

#### Required Settings:
- ✅ **Require a pull request before merging**
  - ✅ Require approvals: `1`
  - ✅ Dismiss stale PR approvals when new commits are pushed
  - ✅ Require review from code owners
- ✅ **Require status checks to pass before merging**
  - ✅ Require branches to be up to date before merging
  - Add these status checks (will appear after first workflow runs):
    - `terraform-validate`
    - `terraform-plan-dev`
    - `terraform-plan-prod`
    - `test-aws-credentials`
- ✅ **Require conversation resolution before merging**
- ✅ **Require signed commits** (optional but recommended)
- ✅ **Include administrators**
- ✅ **Restrict pushes that create files larger than 100MB**

## GitHub Environments

### 1. Create Environments
1. Go to **Settings** → **Environments**
2. Click **New environment**

### 2. Development Environment
- **Name**: `development`
- **Protection rules**: None needed
- **Deployment branches**: All branches

### 3. Production Environment
- **Name**: `production`
- **Protection rules**:
  - ✅ **Required reviewers**: Add yourself (`kashedin`)
  - ✅ **Wait timer**: `5` minutes
  - ✅ **Prevent self-review**: Enabled
- **Deployment branches**: Selected branches
  - Add: `master` (or `main`)

## Repository Security Settings

### 1. Security & Analysis
Go to **Settings** → **Security & analysis**

#### Enable These Features:
- ✅ **Dependency graph**: Enabled
- ✅ **Dependabot alerts**: Enabled
- ✅ **Dependabot security updates**: Enabled
- ✅ **Code scanning alerts**: Enabled
- ✅ **Secret scanning alerts**: Enabled
- ✅ **Push protection**: Enabled

### 2. Actions Permissions
Go to **Settings** → **Actions** → **General**

#### Configure:
- **Actions permissions**: Allow enterprise, and select non-enterprise, actions and reusable workflows
- **Fork pull request workflows**: Require approval for first-time contributors
- **Workflow permissions**: Read repository contents and packages permissions
- ✅ **Allow GitHub Actions to create and approve pull requests**

## Code Owners Configuration

The repository already includes `.github/CODEOWNERS`:

```
# Global code owners
* @kashedin

# Terraform infrastructure
terraform/ @kashedin
.github/workflows/ @kashedin

# Documentation
docs/ @kashedin
*.md @kashedin
```

## Repository Topics and Description

### 1. Repository Description
Go to repository main page → **Settings** → **General**

**Description**: 
```
Automated end-to-end cloud infrastructure deployment using Terraform, GitHub Actions CI/CD, and AWS services
```

**Website**: Leave blank or add your portfolio URL

### 2. Repository Topics
Add these topics (click the gear icon next to "About"):
```
terraform
aws
devops
infrastructure-as-code
ci-cd
github-actions
cloud-infrastructure
automation
s3
ec2
rds
vpc
```

### 3. Repository Settings
- ✅ **Template repository**: Disabled
- ✅ **Require contributors to sign off on web-based commits**: Enabled
- ✅ **Allow merge commits**: Enabled
- ✅ **Allow squash merging**: Enabled
- ✅ **Allow rebase merging**: Disabled
- ✅ **Always suggest updating pull request branches**: Enabled
- ✅ **Allow auto-merge**: Enabled
- ✅ **Automatically delete head branches**: Enabled

## Webhook Configuration (Optional)

If you want Slack notifications:

### 1. Add Slack Webhook
1. Go to **Settings** → **Webhooks**
2. Click **Add webhook**
3. **Payload URL**: Your Slack webhook URL
4. **Content type**: `application/json`
5. **Events**: Choose individual events:
   - Push
   - Pull requests
   - Workflow runs

## Issue and PR Templates

### 1. Issue Template
The repository should include `.github/ISSUE_TEMPLATE/`:

```markdown
---
name: Bug report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: kashedin
---

**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior.

**Expected behavior**
What you expected to happen.

**Environment**
- AWS Region:
- Terraform Version:
- Environment (dev/prod):
```

### 2. PR Template
Create `.github/pull_request_template.md`:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Infrastructure change
- [ ] Documentation update

## Testing
- [ ] Terraform validate passes
- [ ] Terraform plan reviewed
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project standards
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No sensitive data exposed
```

## Verification Steps

### 1. Test Branch Protection
```bash
# Try to push directly to master (should fail)
git checkout master
echo "test" >> README.md
git add README.md
git commit -m "Test direct push"
git push origin master  # Should be blocked
```

### 2. Test PR Workflow
```bash
# Create feature branch
git checkout -b test-branch
echo "# Test PR" >> test.md
git add test.md
git commit -m "Add test file"
git push origin test-branch
# Create PR via GitHub UI
```

### 3. Test Environment Protection
1. Trigger a workflow that deploys to production
2. Verify approval is required
3. Check wait timer works

## Troubleshooting

### Common Issues:

1. **Status checks not appearing**: Run workflows first, then add to branch protection
2. **Environment not protecting**: Ensure correct branch names in deployment branches
3. **Secrets not working**: Verify secret names match exactly in workflows

## Next Steps

After configuring repository settings:

1. ✅ Branch protection configured
2. ✅ Environments created and protected
3. ✅ Security features enabled
4. ✅ Code owners configured
5. → Ready for production deployments!