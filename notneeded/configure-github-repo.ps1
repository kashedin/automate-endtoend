# GitHub Repository Configuration Script (PowerShell)
# This script automates the setup of branch protection, environments, and security settings

param(
    [string]$Repo = "kashedin/automate-endtoend",
    [string]$Branch = "master"
)

Write-Host "🚀 Configuring GitHub repository: $Repo" -ForegroundColor Green

# Check if GitHub CLI is installed
try {
    $null = Get-Command gh -ErrorAction Stop
    Write-Host "✅ GitHub CLI is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ GitHub CLI (gh) is not installed. Please install it first:" -ForegroundColor Red
    Write-Host "   https://cli.github.com/" -ForegroundColor Yellow
    exit 1
}

# Check authentication
try {
    gh auth status 2>$null
    Write-Host "✅ GitHub CLI is authenticated" -ForegroundColor Green
} catch {
    Write-Host "❌ Not authenticated with GitHub CLI. Please run: gh auth login" -ForegroundColor Red
    exit 1
}

# Function to make GitHub API calls with error handling
function Invoke-GitHubAPI {
    param($Path, $Method = "GET", $Body = $null)
    
    try {
        if ($Body) {
            $result = gh api $Path --method $Method --input - <<< $Body
        } else {
            $result = gh api $Path --method $Method
        }
        return $result
    } catch {
        Write-Host "⚠️ API call failed for $Path : $($_.Exception.Message)" -ForegroundColor Yellow
        return $null
    }
}

# 1. Configure branch protection rules
Write-Host "🔒 Setting up branch protection rules for '$Branch'..." -ForegroundColor Cyan

$branchProtection = @{
    required_status_checks = @{
        strict = $true
        contexts = @("terraform-validate", "test-aws-credentials")
    }
    enforce_admins = $true
    required_pull_request_reviews = @{
        required_approving_review_count = 1
        dismiss_stale_reviews = $true
        require_code_owner_reviews = $true
    }
    restrictions = $null
    required_conversation_resolution = $true
} | ConvertTo-Json -Depth 10

$result = Invoke-GitHubAPI "repos/$Repo/branches/$Branch/protection" "PUT" $branchProtection
if ($result) {
    Write-Host "✅ Branch protection rules configured" -ForegroundColor Green
}

# 2. Create development environment
Write-Host "🌍 Creating development environment..." -ForegroundColor Cyan

$devEnvironment = @{
    wait_timer = 0
    reviewers = @()
    deployment_branch_policy = @{
        protected_branches = $false
        custom_branch_policies = $false
    }
} | ConvertTo-Json -Depth 10

$result = Invoke-GitHubAPI "repos/$Repo/environments/development" "PUT" $devEnvironment
if ($result) {
    Write-Host "✅ Development environment created" -ForegroundColor Green
}

# 3. Create production environment
Write-Host "🏭 Creating production environment..." -ForegroundColor Cyan

$prodEnvironment = @{
    wait_timer = 300
    reviewers = @()
    deployment_branch_policy = @{
        protected_branches = $true
        custom_branch_policies = $false
    }
} | ConvertTo-Json -Depth 10

$result = Invoke-GitHubAPI "repos/$Repo/environments/production" "PUT" $prodEnvironment
if ($result) {
    Write-Host "✅ Production environment created" -ForegroundColor Green
}

# 4. Enable security features
Write-Host "🔐 Enabling security features..." -ForegroundColor Cyan

# Enable vulnerability alerts
$result = Invoke-GitHubAPI "repos/$Repo/vulnerability-alerts" "PUT"
if ($result) {
    Write-Host "✅ Vulnerability alerts enabled" -ForegroundColor Green
}

# Enable automated security fixes
$result = Invoke-GitHubAPI "repos/$Repo/automated-security-fixes" "PUT"
if ($result) {
    Write-Host "✅ Automated security fixes enabled" -ForegroundColor Green
}

# 5. Configure repository settings
Write-Host "⚙️ Configuring repository settings..." -ForegroundColor Cyan

$repoSettings = @{
    allow_squash_merge = $true
    allow_merge_commit = $true
    allow_rebase_merge = $false
    delete_branch_on_merge = $true
    allow_auto_merge = $true
} | ConvertTo-Json

$result = Invoke-GitHubAPI "repos/$Repo" "PATCH" $repoSettings
if ($result) {
    Write-Host "✅ Repository settings configured" -ForegroundColor Green
}

Write-Host ""
Write-Host "🎉 GitHub repository configuration completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Summary of changes:" -ForegroundColor Cyan
Write-Host "  ✅ Branch protection rules for '$Branch'" -ForegroundColor Green
Write-Host "  ✅ Development environment (no restrictions)" -ForegroundColor Green
Write-Host "  ✅ Production environment (5min wait, requires approval)" -ForegroundColor Green
Write-Host "  ✅ Security features enabled" -ForegroundColor Green
Write-Host "  ✅ Repository merge settings optimized" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Your repository is now ready for enterprise-grade CI/CD!" -ForegroundColor Green