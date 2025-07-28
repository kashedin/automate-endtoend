# GitHub Secrets Setup Guide

## Required GitHub Secrets

Based on your provided AWS credentials, here are the secrets you need to add to your GitHub repository:

### Navigate to GitHub Secrets
1. Go to your repository: https://github.com/kashedin/automate-endtoend
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** for each secret below

### AWS Credentials Secrets

| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | `ASIA5HZH53W7IQJSEU4U` |
| `AWS_SECRET_ACCESS_KEY` | `qvpMw13yuYU1tH8XshIWoXrnfZGjpY8JHgxUYbNp` |
| `AWS_SESSION_TOKEN` | `IQoJb3JpZ2luX2VjEGUaCXVzLXdlc3QtMiJHMEUCIHBq3GZZBi+I2vIXcuyFDazfEr6Dd5DNkF0uTzLi//eVAiEAobQZA8k1EBT7b7LHp2E19zsoIQhEOQJPUuRCfnnT/4AqrQIIjv//////////ARABGgw5MTAwNzk5NDIwNzgiDADmMoeXidYirOt0piqBArjjKe9q1rqARjc0qp9wmXhOSNv2G8hJgA59DuxT2RdREYGG5myQmqmXSmVxYVqIz4T+agsBXW70YCt0HnUyTyqvIhdNGFj+cdyHvGARyqqBdE5KHI7wW0DZEiS5xhN4Sj/8RXUaCjYntckiXyPcWjTg65NBa0ASp50YSCfJaWYi7fY9Qw7Zp8W4On7QQKBILD5nE/KR5B+Kd8DvrkoFAosc1Fy60Wz1G1c9jpDfQZyekL7k80J6Jvp0m4TdCLsh3hvJ7fjklyhuv6rMf38zvHCHNKL7wSG0r+RsN9aPJgvoPWxtYPBLJC8a5DX2Kt5wq5Jii6ixFfNmUN9CL0u/dImnMO3hncQGOp0BsY1/zlIrrKGONQfVBjnGmAyub9FRRcrP+COR6FORNoIQoC3STtMKAHf1J1yeSP/zRVi0+O9tBpd3nApwXsHdlYUcpmf7ao96h6Gjba/WfgShKKrlqxU7vs9Ngl9/0g8B5TGX1ZK7NcdXhJUKrdMKJKyVFLCVLJhs/meebMlJZGMqMIgavg4WoZLLd229iGdrJxaTCyr7nIiAlIGKLg==` |
| `AWS_DEFAULT_REGION` | `us-west-2` |

### Environment-Specific Secrets

| Secret Name | Value |
|-------------|-------|
| `DEV_ALERT_EMAILS` | `["kashif.din.1991@gmail.com"]` |
| `PROD_ALERT_EMAILS` | `["kashif.din.1991@gmail.com"]` |

### Backend Secrets (Ready to Add!)

The backend infrastructure has been deployed! Add these secrets:

| Secret Name | Value |
|-------------|-------|
| `TF_STATE_BUCKET` | `terraform-state-kashedin-422bf0c7` |
| `TF_STATE_DYNAMODB_TABLE` | `terraform-state-lock-kashedin` |

## Steps to Add Secrets

### 1. Add AWS Credentials
```bash
# You can also use GitHub CLI if you have it installed:
gh secret set AWS_ACCESS_KEY_ID --body "ASIA5HZH53W7IQJSEU4U"
gh secret set AWS_SECRET_ACCESS_KEY --body "qvpMw13yuYU1tH8XshIWoXrnfZGjpY8JHgxUYbNp"
gh secret set AWS_SESSION_TOKEN --body "IQoJb3JpZ2luX2VjEGUaCXVzLXdlc3QtMiJHMEUCIHBq3GZZBi+I2vIXcuyFDazfEr6Dd5DNkF0uTzLi//eVAiEAobQZA8k1EBT7b7LHp2E19zsoIQhEOQJPUuRCfnnT/4AqrQIIjv//////////ARABGgw5MTAwNzk5NDIwNzgiDADmMoeXidYirOt0piqBArjjKe9q1rqARjc0qp9wmXhOSNv2G8hJgA59DuxT2RdREYGG5myQmqmXSmVxYVqIz4T+agsBXW70YCt0HnUyTyqvIhdNGFj+cdyHvGARyqqBdE5KHI7wW0DZEiS5xhN4Sj/8RXUaCjYntckiXyPcWjTg65NBa0ASp50YSCfJaWYi7fY9Qw7Zp8W4On7QQKBILD5nE/KR5B+Kd8DvrkoFAosc1Fy60Wz1G1c9jpDfQZyekL7k80J6Jvp0m4TdCLsh3hvJ7fjklyhuv6rMf38zvHCHNKL7wSG0r+RsN9aPJgvoPWxtYPBLJC8a5DX2Kt5wq5Jii6ixFfNmUN9CL0u/dImnMO3hncQGOp0BsY1/zlIrrKGONQfVBjnGmAyub9FRRcrP+COR6FORNoIQoC3STtMKAHf1J1yeSP/zRVi0+O9tBpd3nApwXsHdlYUcpmf7ao96h6Gjba/WfgShKKrlqxU7vs9Ngl9/0g8B5TGX1ZK7NcdXhJUKrdMKJKyVFLCVLJhs/meebMlJZGMqMIgavg4WoZLLd229iGdrJxaTCyr7nIiAlIGKLg=="
gh secret sAWS_DEFAULT_REGION et --body "us-west-2"
gh secret set DEV_ALERT_EMAILS --body '["kashif.din.1991@gmail.com"]'
gh secret set PROD_ALERT_EMAILS --body '["kashif.din.1991@gmail.com"]'
```

### 2. Test the Setup
After adding the secrets, you can test them by:

1. Go to **Actions** tab in your repository
2. Click on **Test AWS Access** workflow
3. Click **Run workflow** → **Run workflow**
4. Monitor the results to ensure credentials work

### 3. Backend Infrastructure ✅ COMPLETED!
The backend infrastructure has been successfully deployed:

- **S3 Bucket**: `terraform-state-kashedin-422bf0c7`
- **DynamoDB Table**: `terraform-state-lock-kashedin`
- **Region**: `us-west-2`

All backend secrets are ready to be added to GitHub!

## Security Notes

⚠️ **Important**: The AWS session token you provided is temporary and will expire. For production use, you should:

1. Create a dedicated IAM user for GitHub Actions
2. Generate permanent access keys (without session token)
3. Use least privilege IAM policies
4. Rotate keys regularly

## Next Steps

1. ✅ Add all secrets to GitHub
2. ✅ Run the test workflow to verify access
3. ✅ Deploy backend infrastructure
4. ✅ Update backend secrets
5. ✅ Configure repository settings and branch protection