# AWS Credentials Setup Script
# This script helps you configure AWS credentials for deployment

Write-Host "🔐 AWS Credentials Setup" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Check if AWS CLI is available
try {
    $awsVersion = & aws --version 2>$null
    Write-Host "✅ AWS CLI found: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS CLI not found. Please install AWS CLI first." -ForegroundColor Red
    Write-Host "Download from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

# Check current AWS configuration
Write-Host "`n🔍 Checking current AWS configuration..." -ForegroundColor Yellow

try {
    $identityJson = & aws sts get-caller-identity 2>$null
    if ($identityJson) {
        $identity = $identityJson | ConvertFrom-Json
        Write-Host "✅ AWS credentials are configured!" -ForegroundColor Green
        Write-Host "Account ID: $($identity.Account)" -ForegroundColor White
        Write-Host "User ARN: $($identity.Arn)" -ForegroundColor White
        Write-Host "User ID: $($identity.UserId)" -ForegroundColor White
    } else {
        throw "No identity returned"
    }
} catch {
    Write-Host "❌ AWS credentials not configured or invalid." -ForegroundColor Red
    Write-Host "`n📝 To configure AWS credentials, you have several options:" -ForegroundColor Yellow
    Write-Host "1. Run: aws configure" -ForegroundColor White
    Write-Host "2. Set environment variables:" -ForegroundColor White
    Write-Host "   `$env:AWS_ACCESS_KEY_ID='your-access-key'" -ForegroundColor Gray
    Write-Host "   `$env:AWS_SECRET_ACCESS_KEY='your-secret-key'" -ForegroundColor Gray
    Write-Host "   `$env:AWS_DEFAULT_REGION='us-west-2'" -ForegroundColor Gray
    Write-Host "3. Use AWS SSO: aws sso login" -ForegroundColor White
    
    $response = Read-Host "`nWould you like to configure credentials now? (y/n)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        Write-Host "`n🔧 Starting AWS configuration..." -ForegroundColor Cyan
        & aws configure
        
        # Test again after configuration
        try {
            $identityJson = & aws sts get-caller-identity
            $identity = $identityJson | ConvertFrom-Json
            Write-Host "✅ AWS credentials configured successfully!" -ForegroundColor Green
            Write-Host "Account ID: $($identity.Account)" -ForegroundColor White
        } catch {
            Write-Host "❌ Configuration failed. Please check your credentials." -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "⚠️  Please configure AWS credentials before proceeding with deployment." -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "`n🚀 AWS credentials are ready for deployment!" -ForegroundColor Green
Write-Host "You can now proceed with Terraform deployment." -ForegroundColor White