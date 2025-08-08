# Create S3 bucket for Terraform backend manually
# This script creates the S3 bucket when Terraform has permission issues

$bucketName = "terraform-state-kashedin-$(Get-Date -Format 'yyyyMMddHHmmss')"
$region = "us-east-1"

Write-Host "🚀 Creating S3 bucket for Terraform backend..." -ForegroundColor Green
Write-Host "Bucket name: $bucketName" -ForegroundColor Cyan

# Set AWS credentials - REPLACE WITH YOUR ACTUAL CREDENTIALS
$env:AWS_ACCESS_KEY_ID = "YOUR_AWS_ACCESS_KEY_ID"
$env:AWS_SECRET_ACCESS_KEY = "YOUR_AWS_SECRET_ACCESS_KEY"
$env:AWS_SESSION_TOKEN = "YOUR_AWS_SESSION_TOKEN"
$env:AWS_DEFAULT_REGION = $region

Write-Host "✅ AWS credentials configured" -ForegroundColor Green

# Create bucket using PowerShell (since AWS CLI might not be available)
try {
    # Try to create bucket using AWS CLI if available
    aws s3 mb s3://$bucketName --region $region
    Write-Host "✅ S3 bucket created successfully!" -ForegroundColor Green
    
    # Enable versioning
    aws s3api put-bucket-versioning --bucket $bucketName --versioning-configuration Status=Enabled
    Write-Host "✅ S3 bucket versioning enabled!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ AWS CLI not available or failed. Please create bucket manually:" -ForegroundColor Red
    Write-Host "1. Go to AWS S3 Console" -ForegroundColor Yellow
    Write-Host "2. Create bucket: $bucketName" -ForegroundColor Yellow
    Write-Host "3. Enable versioning" -ForegroundColor Yellow
    Write-Host "4. Keep default settings" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Backend Configuration:" -ForegroundColor Yellow
Write-Host "=========================" -ForegroundColor Yellow
Write-Host "S3 Bucket: $bucketName" -ForegroundColor Cyan
Write-Host "DynamoDB Table: terraform-state-lock-kashedin" -ForegroundColor Cyan
Write-Host "Region: $region" -ForegroundColor Cyan

Write-Host ""
Write-Host "🔧 GitHub Secrets to Update:" -ForegroundColor Yellow
Write-Host "=============================" -ForegroundColor Yellow
Write-Host "TF_STATE_BUCKET: $bucketName" -ForegroundColor Cyan
Write-Host "TF_STATE_DYNAMODB_TABLE: terraform-state-lock-kashedin" -ForegroundColor Cyan

Write-Host ""
Write-Host "✨ Backend setup complete! Use these values in your GitHub secrets." -ForegroundColor Green