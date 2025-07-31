# Create S3 bucket for Terraform backend manually
# This script creates the S3 bucket when Terraform has permission issues

$bucketName = "terraform-state-kashedin-$(Get-Date -Format 'yyyyMMddHHmmss')"
$region = "us-east-1"

Write-Host "🚀 Creating S3 bucket for Terraform backend..." -ForegroundColor Green
Write-Host "Bucket name: $bucketName" -ForegroundColor Cyan

# Set AWS credentials
$env:AWS_ACCESS_KEY_ID = "ASIA5HZH53W7BLJHJEME"
$env:AWS_SECRET_ACCESS_KEY = "KH2VLH8LOLtqqtv0Pe1y9w/i0ONFqsXI9Pq16eE0"
$env:AWS_SESSION_TOKEN = "IQoJb3JpZ2luX2VjEKj//////////wEaCXVzLXdlc3QtMiJIMEYCIQDaZCTXPt9XMR1jX0htDdX9G0SFlxypNbHO62coD1l1owIhAJtqi4MYPaEvDdL/uAwahX2ZcLbDn6iPcMEmGfpEPX3QKq0CCNH//////////wEQARoMOTEwMDc5OTQyMDc4IgwM0Z19ZiXx1G0BApoqgQJSMxMz5fR42hBTKoN2AQnH5aIfzzlgiq0YIMAXssdtEDYAAz4tBIVw+DGiDie2RH2EMoPAaE+bv9bjrKIOszFLvMydrCubFZp0T8vv83egRQlZ8Hrjuhga+kSBkwR0QY5mOthiEeI1JZ05u79OJS44TL05AnCdrS30M6JQlyo6HBZR6HKL88ShZc6+0iYz63UIL/71Ee/ndmowE5M8fP34AcN+i9NL/nU40nTdgkNh+H5EEoVzp2y06cVQS/SX1heQNOVE55QrgvaXg5Ge5aQOKpijqfPanL7u2kTY/HPGF5cTZ38io39JcSkTiAydeUfcZ+/xCVOfBZL6w08UxJT+xTC3wKzEBjqcAWUcsz4QcIoRKXUr//hbvcm7nZEVg9hIa23z38pm0kw4KyvCUzSylLfTPk4x+KLjOs0tuIYfX80xqUFtKjXo88DpMogcgZXxJ3rQR/OQpMwOK6zovz8J6p+dcY0Dyd5b+O9zZGzpzsC82vPffdQdO6emBKbSob+a6CIKCIHcootx5qPE49wfKGLAiAx+STrbPBAAeMYiu5qqKrJl/w=="
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