#!/bin/bash
# GitHub Repository Configuration Script
# This script automates the setup of branch protection, environments, and security settings

set -e

REPO="kashedin/automate-endtoend"
BRANCH="master"

echo "🚀 Configuring GitHub repository: $REPO"

# Check if GitHub CLI is installed and authenticated
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed. Please install it first:"
    echo "   https://cli.github.com/"
    exit 1
fi

# Verify authentication
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI. Please run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is installed and authenticated"

# 1. Configure branch protection rules
echo "🔒 Setting up branch protection rules for '$BRANCH'..."

gh api repos/$REPO/branches/$BRANCH/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["terraform-validate","test-aws-credentials"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true,"require_code_owner_reviews":true}' \
  --field restrictions=null \
  --field required_conversation_resolution=true

echo "✅ Branch protection rules configured"

# 2. Create development environment
echo "🌍 Creating development environment..."

gh api repos/$REPO/environments/development \
  --method PUT \
  --field wait_timer=0 \
  --field reviewers='[]' \
  --field deployment_branch_policy='{"protected_branches":false,"custom_branch_policies":false}'

echo "✅ Development environment created"

# 3. Create production environment
echo "🏭 Creating production environment..."

gh api repos/$REPO/environments/production \
  --method PUT \
  --field wait_timer=300 \
  --field reviewers='[{"type":"User","id":null}]' \
  --field deployment_branch_policy='{"protected_branches":true,"custom_branch_policies":false}'

echo "✅ Production environment created"

# 4. Enable security features
echo "🔐 Enabling security features..."

# Enable vulnerability alerts
gh api repos/$REPO/vulnerability-alerts --method PUT

# Enable automated security fixes
gh api repos/$REPO/automated-security-fixes --method PUT

echo "✅ Security features enabled"

# 5. Configure repository settings
echo "⚙️ Configuring repository settings..."

gh api repos/$REPO \
  --method PATCH \
  --field allow_squash_merge=true \
  --field allow_merge_commit=true \
  --field allow_rebase_merge=false \
  --field delete_branch_on_merge=true \
  --field allow_auto_merge=true

echo "✅ Repository settings configured"

echo "🎉 GitHub repository configuration completed successfully!"
echo ""
echo "📋 Summary of changes:"
echo "  ✅ Branch protection rules for '$BRANCH'"
echo "  ✅ Development environment (no restrictions)"
echo "  ✅ Production environment (5min wait, requires approval)"
echo "  ✅ Security features enabled"
echo "  ✅ Repository merge settings optimized"
echo ""
echo "🚀 Your repository is now ready for enterprise-grade CI/CD!"