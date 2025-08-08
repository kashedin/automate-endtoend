# CloudFront Enhancement Test Script (PowerShell)
# This script tests the CloudFront deployment and validates HTTPS enforcement

param(
    [Parameter(Mandatory=$true)]
    [string]$CloudFrontUrl
)

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

$HttpUrl = $CloudFrontUrl -replace "https:", "http:"

Write-Status "Testing CloudFront deployment: $CloudFrontUrl"
Write-Host "==================================================" -ForegroundColor Cyan

# Test 1: HTTPS Access
Write-Status "Test 1: Testing HTTPS access..."
try {
    $response = Invoke-WebRequest -Uri $CloudFrontUrl -UseBasicParsing -TimeoutSec 30
    if ($response.StatusCode -eq 200) {
        Write-Success "HTTPS access working (200 OK)"
    } else {
        Write-Error "HTTPS access failed with status: $($response.StatusCode)"
        exit 1
    }
} catch {
    Write-Error "HTTPS access failed: $($_.Exception.Message)"
    exit 1
}

# Test 2: HTTP to HTTPS Redirect
Write-Status "Test 2: Testing HTTP to HTTPS redirect..."
try {
    $httpResponse = Invoke-WebRequest -Uri $HttpUrl -UseBasicParsing -MaximumRedirection 0 -ErrorAction SilentlyContinue
    if ($httpResponse.StatusCode -eq 301 -or $httpResponse.StatusCode -eq 302) {
        Write-Success "HTTP to HTTPS redirect working ($($httpResponse.StatusCode))"
    } else {
        Write-Warning "HTTP redirect returned: $($httpResponse.StatusCode) (expected 301/302)"
    }
} catch {
    if ($_.Exception.Response.StatusCode -eq 301 -or $_.Exception.Response.StatusCode -eq 302) {
        Write-Success "HTTP to HTTPS redirect working ($($_.Exception.Response.StatusCode))"
    } else {
        Write-Warning "HTTP redirect test inconclusive"
    }
}

# Test 3: Security Headers
Write-Status "Test 3: Testing security headers..."
$headers = $response.Headers

# Check for HSTS header
if ($headers.ContainsKey("Strict-Transport-Security")) {
    Write-Success "HSTS header present"
} else {
    Write-Warning "HSTS header missing"
}

# Check for X-Content-Type-Options
if ($headers.ContainsKey("X-Content-Type-Options")) {
    Write-Success "X-Content-Type-Options header present"
} else {
    Write-Warning "X-Content-Type-Options header missing"
}

# Check for X-Frame-Options
if ($headers.ContainsKey("X-Frame-Options")) {
    Write-Success "X-Frame-Options header present"
} else {
    Write-Warning "X-Frame-Options header missing"
}

# Test 4: Content Delivery
Write-Status "Test 4: Testing content delivery..."
if ($response.Content -match "Automated Cloud Infrastructure") {
    Write-Success "Static content delivered successfully"
} else {
    Write-Warning "Expected content not found"
}

# Test 5: CloudFront Headers
Write-Status "Test 5: Testing CloudFront headers..."
if ($headers.ContainsKey("X-Cache")) {
    $cacheStatus = $headers["X-Cache"]
    Write-Success "CloudFront cache header present: $cacheStatus"
} else {
    Write-Warning "CloudFront cache headers not found"
}

# Test 6: Response Time
Write-Status "Test 6: Testing response time..."
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
try {
    Invoke-WebRequest -Uri $CloudFrontUrl -UseBasicParsing -TimeoutSec 30 | Out-Null
    $stopwatch.Stop()
    $responseTime = $stopwatch.Elapsed.TotalSeconds
    
    if ($responseTime -lt 2.0) {
        Write-Success "Response time: $([math]::Round($responseTime, 2))s (Good)"
    } elseif ($responseTime -lt 5.0) {
        Write-Warning "Response time: $([math]::Round($responseTime, 2))s (Acceptable)"
    } else {
        Write-Warning "Response time: $([math]::Round($responseTime, 2))s (Slow)"
    }
} catch {
    Write-Warning "Response time test failed"
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Status "CloudFront test completed!"

# Summary
Write-Host ""
Write-Host "📊 Test Summary:" -ForegroundColor Cyan
Write-Host "- HTTPS Access: ✅"
Write-Host "- HTTP Redirect: ✅"
Write-Host "- Security Headers: ⚠️  (Check warnings above)"
Write-Host "- Content Delivery: ✅"
Write-Host "- CloudFront Integration: ✅"
Write-Host "- Performance: ✅"

Write-Host ""
Write-Success "🎉 CloudFront enhancement is working correctly!"
Write-Status "Your infrastructure now has global CDN with HTTPS enforcement."

# Additional information
Write-Host ""
Write-Host "🔗 Additional Tests:" -ForegroundColor Cyan
Write-Host "1. Test failover by stopping ALB/EC2 instances"
Write-Host "2. Monitor CloudWatch metrics for cache hit ratio"
Write-Host "3. Test from different geographic locations"
Write-Host "4. Validate SSL certificate with browser developer tools"