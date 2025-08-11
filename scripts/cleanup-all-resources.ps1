# Complete Infrastructure Cleanup Script for AWS Academy Sandbox
# This script destroys all Terraform-managed resources to avoid charges and resource limits

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "prod", "both")]
    [string]$Environment = "both",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipConfirmation = $false
)

Write-Host "🧹 AWS Infrastructure Cleanup Script" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Yellow

# Function to cleanup a specific environment
function Cleanup-Environment {
    param(
        [string]$EnvName
    )
    
    Write-Host "`n🔥 Cleaning up $EnvName environment..." -ForegroundColor Red
    Write-Host "Environment: $EnvName" -ForegroundColor Cyan
    
    $envPath = "terraform/environments/$EnvName"
    
    if (-not (Test-Path $envPath)) {
        Write-Host "❌ Environment path not found: $envPath" -ForegroundColor Red
        return $false
    }
    
    try {
        # Change to environment directory
        Push-Location $envPath
        
        Write-Host "📋 Step 1: Terraform Init" -ForegroundColor Yellow
        terraform init
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Terraform init failed" -ForegroundColor Red
            return $false
        }
        
        Write-Host "📋 Step 2: Terraform Plan (Destroy)" -ForegroundColor Yellow
        terraform plan -destroy -out=destroy.tfplan
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Terraform destroy plan failed" -ForegroundColor Red
            return $false
        }
        
        if (-not $SkipConfirmation) {
            Write-Host "`n⚠️  WARNING: This will destroy ALL resources in $EnvName environment!" -ForegroundColor Red
            Write-Host "This includes:" -ForegroundColor Yellow
            Write-Host "- CloudFront Distribution" -ForegroundColor White
            Write-Host "- Application Load Balancer" -ForegroundColor White
            Write-Host "- Auto Scaling Groups & EC2 Instances" -ForegroundColor White
            Write-Host "- RDS Aurora Database" -ForegroundColor White
            Write-Host "- S3 Buckets (with all content)" -ForegroundColor White
            Write-Host "- VPC and all networking components" -ForegroundColor White
            Write-Host "- CloudWatch Log Groups" -ForegroundColor White
            Write-Host "- SNS Topics and Alarms" -ForegroundColor White
            
            $confirmation = Read-Host "`nType 'DESTROY' to confirm destruction of $EnvName environment"
            if ($confirmation -ne "DESTROY") {
                Write-Host "❌ Cleanup cancelled by user" -ForegroundColor Yellow
                return $false
            }
        }
        
        Write-Host "📋 Step 3: Terraform Destroy" -ForegroundColor Yellow
        if ($Force) {
            terraform destroy -auto-approve
        } else {
            terraform apply -auto-approve destroy.tfplan
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Successfully destroyed $EnvName environment" -ForegroundColor Green
            
            # Clean up plan file
            if (Test-Path "destroy.tfplan") {
                Remove-Item "destroy.tfplan" -Force
            }
            
            return $true
        } else {
            Write-Host "❌ Terraform destroy failed for $EnvName" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "❌ Error during cleanup: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    } finally {
        Pop-Location
    }
}

# Function to cleanup orphaned resources via AWS CLI
function Cleanup-OrphanedResources {
    Write-Host "`n🔍 Checking for orphaned resources..." -ForegroundColor Yellow
    
    # Check if AWS CLI is available
    try {
        aws --version | Out-Null
    } catch {
        Write-Host "⚠️  AWS CLI not found. Skipping orphaned resource cleanup." -ForegroundColor Yellow
        return
    }
    
    Write-Host "🧹 Cleaning up potential orphaned resources..." -ForegroundColor Yellow
    
    # List and optionally delete CloudFront distributions
    Write-Host "📡 Checking CloudFront distributions..." -ForegroundColor Cyan
    try {
        $distributions = aws cloudfront list-distributions --query 'DistributionList.Items[?contains(Comment, `dev`) || contains(Comment, `prod`)].{Id:Id,Comment:Comment,Status:Status}' --output table 2>$null
        if ($distributions) {
            Write-Host $distributions
            Write-Host "⚠️  Found CloudFront distributions. These may take time to delete automatically." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Could not check CloudFront distributions" -ForegroundColor Yellow
    }
    
    # List S3 buckets that might be left behind
    Write-Host "🪣 Checking S3 buckets..." -ForegroundColor Cyan
    try {
        $buckets = aws s3 ls | Select-String -Pattern "(dev-|prod-)"
        if ($buckets) {
            Write-Host "Found potentially related S3 buckets:" -ForegroundColor Yellow
            $buckets | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
            
            if (-not $SkipConfirmation) {
                $cleanupS3 = Read-Host "`nDelete these S3 buckets? (y/N)"
                if ($cleanupS3 -eq "y" -or $cleanupS3 -eq "Y") {
                    $buckets | ForEach-Object {
                        $bucketName = ($_ -split '\s+')[-1]
                        Write-Host "🗑️  Deleting bucket: $bucketName" -ForegroundColor Red
                        aws s3 rb "s3://$bucketName" --force 2>$null
                    }
                }
            }
        }
    } catch {
        Write-Host "⚠️  Could not check S3 buckets" -ForegroundColor Yellow
    }
}

# Main execution
Write-Host "Environment(s) to cleanup: $Environment" -ForegroundColor Cyan
Write-Host "Force mode: $Force" -ForegroundColor Cyan
Write-Host "Skip confirmation: $SkipConfirmation" -ForegroundColor Cyan

$success = $true

# Cleanup based on environment parameter
switch ($Environment) {
    "dev" {
        $success = Cleanup-Environment -EnvName "dev"
    }
    "prod" {
        $success = Cleanup-Environment -EnvName "prod"
    }
    "both" {
        $devSuccess = Cleanup-Environment -EnvName "dev"
        $prodSuccess = Cleanup-Environment -EnvName "prod"
        $success = $devSuccess -and $prodSuccess
    }
}

# Cleanup orphaned resources
if ($success) {
    Cleanup-OrphanedResources
}

# Final summary
Write-Host "`n" -NoNewline
if ($success) {
    Write-Host "🎉 Cleanup completed successfully!" -ForegroundColor Green
    Write-Host "✅ All Terraform-managed resources have been destroyed" -ForegroundColor Green
    Write-Host "💰 This should prevent any ongoing AWS charges" -ForegroundColor Green
    Write-Host "🔄 You can safely restart your AWS Academy lab session" -ForegroundColor Green
} else {
    Write-Host "❌ Cleanup completed with errors" -ForegroundColor Red
    Write-Host "⚠️  Some resources may still exist and incur charges" -ForegroundColor Yellow
    Write-Host "🔍 Check the AWS Console manually for any remaining resources" -ForegroundColor Yellow
}

Write-Host "`n📋 Cleanup Summary:" -ForegroundColor Yellow
Write-Host "- Environment(s): $Environment" -ForegroundColor White
Write-Host "- Status: $(if ($success) { 'SUCCESS' } else { 'FAILED' })" -ForegroundColor $(if ($success) { 'Green' } else { 'Red' })
Write-Host "- Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White

# Exit with appropriate code
exit $(if ($success) { 0 } else { 1 })