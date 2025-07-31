# GitHub Secrets Setup Script for AWS Credentials
# This script helps you set up the required GitHub secrets for the CI/CD pipeline

Write-Host "🚀 Setting up GitHub Secrets for Automated Cloud Infrastructure" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green

# AWS Credentials - REPLACE WITH YOUR ACTUAL CREDENTIALS
$AWS_ACCESS_KEY_ID = "YOUR_AWS_ACCESS_KEY_ID"
$AWS_SECRET_ACCESS_KEY = "YOUR_AWS_SECRET_ACCESS_KEY"
$AWS_SESSION_TOKEN = "YOUR_AWS_SESSION_TOKEN"
$AWS_DEFAULT_REGION = "us-east-1"

Write-Host "📋 Your AWS Credentials:" -ForegroundColor Yellow
Write-Host "Access Key ID: $AWS_ACCESS_KEY_ID" -ForegroundColor Cyan
Write-Host "Secret Access Key: $($AWS_SECRET_ACCESS_KEY.Substring(0,8))..." -ForegroundColor Cyan
Write-Host "Session Token: $($AWS_SESSION_TOKEN.Substring(0,20))..." -ForegroundColor Cyan
Write-Host "Default Region: $AWS_DEFAULT_REGION" -ForegroundColor Cyan
Write-Host ""

# Test AWS credentials
Write-Host "🔍 Testing AWS Credentials..." -ForegroundColor Yellow
$env:AWS_ACCESS_KEY_ID = $AWS_ACCESS_KEY_ID
$env:AWS_SECRET_ACCESS_KEY = $AWS_SECRET_ACCESS_KEY
$env:AWS_SESSION_TOKEN = $AWS_SESSION_TOKEN
$env:AWS_DEFAULT_REGION = $AWS_DEFAULT_REGION

try {
    $identity = aws sts get-caller-identity --output json | ConvertFrom-Json
    Write-Host "✅ AWS Credentials Valid!" -ForegroundColor Green
    Write-Host "Account ID: $($identity.Account)" -ForegroundColor Cyan
    Write-Host "User ARN: $($identity.Arn)" -ForegroundColor Cyan
    Write-Host "User ID: $($identity.UserId)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ AWS Credentials Test Failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📝 GitHub Repository Setup Instructions:" -ForegroundColor Yellow
Write-Host "=========================================" -ForegroundColor Yellow

Write-Host "1. Go to your GitHub repository: https://github.com/YOUR_USERNAME/automated-cloud-infrastructure" -ForegroundColor White
Write-Host "2. Navigate to Settings → Secrets and variables → Actions" -ForegroundColor White
Write-Host "3. Click 'New repository secret' and add the following secrets:" -ForegroundColor White
Write-Host ""

Write-Host "Required GitHub Secrets:" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green

$secrets = @(
    @{Name="AWS_ACCESS_KEY_ID"; Value=$AWS_ACCESS_KEY_ID; Description="AWS Access Key ID"},
    @{Name="AWS_SECRET_ACCESS_KEY"; Value=$AWS_SECRET_ACCESS_KEY; Description="AWS Secret Access Key"},
    @{Name="AWS_SESSION_TOKEN"; Value=$AWS_SESSION_TOKEN; Description="AWS Session Token (for temporary credentials)"},
    @{Name="AWS_DEFAULT_REGION"; Value=$AWS_DEFAULT_REGION; Description="Default AWS Region"},
    @{Name="TF_STATE_BUCKET"; Value="terraform-state-$(Get-Random -Minimum 100000 -Maximum 999999)"; Description="S3 bucket for Terraform state"},
    @{Name="TF_STATE_DYNAMODB_TABLE"; Value="terraform-state-lock"; Description="DynamoDB table for state locking"}
)

foreach ($secret in $secrets) {
    Write-Host "Secret Name: $($secret.Name)" -ForegroundColor Cyan
    Write-Host "Value: $($secret.Value)" -ForegroundColor White
    Write-Host "Description: $($secret.Description)" -ForegroundColor Gray
    Write-Host "---" -ForegroundColor Gray
}

Write-Host ""
Write-Host "🔧 Additional Setup Steps:" -ForegroundColor Yellow
Write-Host "==========================" -ForegroundColor Yellow

Write-Host "1. Create Terraform Backend Resources:" -ForegroundColor White
Write-Host "   - Run: terraform init && terraform apply in terraform/backend-setup/" -ForegroundColor Cyan

Write-Host "2. Set up Branch Protection Rules:" -ForegroundColor White
Write-Host "   - Go to Settings → Branches → Add rule for 'main' branch" -ForegroundColor Cyan

Write-Host "3. Create GitHub Environments:" -ForegroundColor White
Write-Host "   - Go to Settings → Environments" -ForegroundColor Cyan
Write-Host "   - Create 'development' and 'production' environments" -ForegroundColor Cyan

Write-Host ""
Write-Host "🚀 Ready to Deploy!" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green
Write-Host "After setting up the secrets, you can:" -ForegroundColor White
Write-Host "1. Push your code to trigger the CI/CD pipeline" -ForegroundColor Cyan
Write-Host "2. Create a pull request to test the validation workflow" -ForegroundColor Cyan
Write-Host "3. Merge to main branch to deploy infrastructure" -ForegroundColor Cyan

Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor Yellow
Write-Host "- GitHub Setup Guide: docs/github-setup.md" -ForegroundColor Cyan
Write-Host "- Deployment Guide: scripts/deploy-infrastructure.md" -ForegroundColor Cyan
Write-Host "- Testing Guide: scripts/test-cicd-pipeline.md" -ForegroundColor Cyan

Write-Host ""
Write-Host "✨ Setup Complete! Your credentials are ready for GitHub Actions." -ForegroundColor Green