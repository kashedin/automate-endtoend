# 🚀 CloudFront CDN Enhancement

## Overview

This enhancement adds **Amazon CloudFront CDN** with **S3 static website failover** to the existing 3-tier architecture, providing:

- **Global content delivery** with edge locations worldwide
- **HTTPS-only access** with automatic HTTP redirect
- **Automatic failover** from ALB to S3 static site
- **Enhanced security** with response headers policy
- **Cost optimization** for AWS Academy sandbox environment

## 🏗️ Architecture Enhancement

```
Internet → CloudFront CDN → Primary: ALB → EC2 Web Tier
                        ↘ Failover: S3 Static Site
```

### Components Added

1. **CloudFront Distribution**
   - Global CDN with edge locations
   - HTTPS-only with TLS 1.2+
   - Custom error pages
   - Security headers policy

2. **S3 Static Website**
   - Failover destination
   - Static content hosting
   - Origin Access Control (OAC)
   - Lifecycle policies

3. **CDN Module**
   - Reusable Terraform module
   - Configurable price class
   - Origin groups for failover

## 🔒 Security Features

### HTTPS Enforcement
- **Viewer Protocol Policy**: `redirect-to-https`
- **Minimum TLS Version**: TLS 1.2
- **CloudFront Default Certificate**: Used for sandbox compatibility

### Security Headers
- **Strict-Transport-Security**: HSTS with 1-year max-age
- **X-Content-Type-Options**: nosniff
- **X-Frame-Options**: DENY
- **Referrer-Policy**: strict-origin-when-cross-origin

### Origin Security
- **Origin Access Control (OAC)**: Secure S3 access
- **Private S3 bucket**: No public access
- **ALB internal communication**: HTTP allowed internally

## 📊 Performance Optimizations

### Caching Strategy
- **Static assets** (`/static/*`): Long-term caching (1 year)
- **API endpoints** (`/api/*`): No caching
- **Default content**: Medium-term caching (1 hour)

### Cost Optimization
- **Price Class**: PriceClass_100 (US, Canada, Europe only)
- **Compression**: Enabled for all content
- **Efficient origin selection**: ALB primary, S3 failover

## 🚀 Deployment

### Prerequisites
- Existing 3-tier infrastructure deployed
- AWS credentials configured in GitHub Secrets
- Terraform 1.6.0+

### Deploy via GitHub Actions

1. **Navigate to Actions tab** in your GitHub repository
2. **Select "Deploy CloudFront Enhancement"** workflow
3. **Configure parameters**:
   - Environment: `dev` or `prod`
   - Terraform Action: `plan` or `apply`
4. **Run workflow**

### Manual Deployment

```bash
# Navigate to sandbox configuration
cd terraform/sandbox-3tier

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var="environment=dev"

# Apply changes
terraform apply -var="environment=dev"
```

## 📋 Outputs

After successful deployment, you'll receive:

- **CloudFront HTTPS URL**: `https://d1234567890abc.cloudfront.net`
- **ALB HTTP URL**: `http://alb-dns-name.region.elb.amazonaws.com`
- **S3 Static Website URL**: `http://bucket-name.s3-website-region.amazonaws.com`

## 🧪 Testing

### Test HTTPS Enforcement
```bash
# This should redirect to HTTPS
curl -I http://d1234567890abc.cloudfront.net

# This should return 200 OK
curl -I https://d1234567890abc.cloudfront.net
```

### Test Failover
1. **Stop ALB/EC2 instances** (simulate failure)
2. **Access CloudFront URL** - should serve S3 static content
3. **Restart ALB/EC2** - should return to dynamic content

### Test Security Headers
```bash
curl -I https://d1234567890abc.cloudfront.net
# Look for:
# strict-transport-security: max-age=31536000; includeSubDomains
# x-content-type-options: nosniff
# x-frame-options: DENY
```

## 📈 Benefits Achieved

### Performance
- ✅ **Faster load times** globally via edge locations
- ✅ **Reduced origin load** through intelligent caching
- ✅ **Automatic compression** for all content types
- ✅ **HTTP/2 support** for modern browsers

### Reliability
- ✅ **99.99% availability** SLA from CloudFront
- ✅ **Automatic failover** to S3 static site
- ✅ **DDoS protection** via AWS Shield Standard
- ✅ **Health checks** and error handling

### Security
- ✅ **HTTPS-only access** with modern TLS
- ✅ **Security headers** for XSS/clickjacking protection
- ✅ **Origin protection** via OAC
- ✅ **No direct S3 access** from internet

### Cost Efficiency
- ✅ **Reduced data transfer costs** from EC2
- ✅ **Optimized price class** for sandbox budget
- ✅ **Efficient caching** reduces origin requests
- ✅ **Pay-per-use** CloudFront pricing

## 🔧 Configuration Options

### Price Classes
- `PriceClass_All`: All edge locations (highest cost)
- `PriceClass_200`: US, Canada, Europe, Asia, Middle East, Africa
- `PriceClass_100`: US, Canada, Europe only (lowest cost) ← **Default**

### Cache Behaviors
- **Static assets**: Long-term caching with compression
- **API endpoints**: No caching, all headers forwarded
- **Default**: Medium-term caching with query strings

### Failover Criteria
- HTTP status codes: 403, 404, 500, 502, 503, 504
- Connection timeouts to ALB
- Health check failures

## 🛠️ Troubleshooting

### Common Issues

1. **CloudFront deployment takes 15-20 minutes**
   - This is normal for global distribution
   - Monitor via AWS Console

2. **S3 bucket policy errors**
   - Ensure OAC is created before bucket policy
   - Check CloudFront distribution ARN

3. **HTTPS certificate issues**
   - Using CloudFront default certificate
   - No custom domain configuration needed

### Monitoring

- **CloudWatch metrics**: CloudFront and S3 metrics enabled
- **Access logs**: Stored in dedicated S3 bucket
- **Error tracking**: Custom error pages configured

## 📚 Additional Resources

- [AWS CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [S3 Static Website Hosting](https://docs.aws.amazon.com/s3/latest/userguide/WebsiteHosting.html)
- [CloudFront Security Best Practices](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/security.html)

## 🎯 Next Steps

Consider these additional enhancements:

1. **Custom Domain**: Add Route 53 and ACM certificate
2. **WAF Integration**: Add AWS WAF for advanced security
3. **Lambda@Edge**: Add serverless functions at edge
4. **Real User Monitoring**: Add CloudWatch RUM
5. **Advanced Caching**: Implement cache invalidation strategies

---

**🎉 Congratulations!** Your infrastructure now includes enterprise-grade global content delivery with automatic failover and enhanced security!