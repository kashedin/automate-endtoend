# 🔄 Update GitHub Secrets with New AWS Credentials

## Quick Update Guide

Since you already have the GitHub repository, you just need to update the secrets with your new AWS credentials.

### Step 1: Go to Repository Secrets
1. Go to your GitHub repository: `https://github.com/kashedin/automate-endtoend`
2. Navigate to **Settings** → **Secrets and variables** → **Actions**

### Step 2: Update These 6 Secrets
Click on each secret name and update with your new values:

| Secret Name | Description |
|-------------|-------------|
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key ID |
| `AWS_SECRET_ACCESS_KEY` | Your AWS Secret Access Key |
| `AWS_SESSION_TOKEN` | Your AWS Session Token (for temporary credentials) |
| `AWS_DEFAULT_REGION` | `us-east-1` |
| `TF_STATE_BUCKET` | Keep existing or update to unique name |
| `TF_STATE_DYNAMODB_TABLE` | Keep existing or update to `terraform-state-lock-kashedin` |

### Step 3: Test the New Credentials
1. Go to **Actions** tab in your repository
2. Find **"Test AWS Access"** workflow
3. Click **"Run workflow"** → **"Run workflow"**
4. Verify it completes successfully with green checkmark ✅

### Step 4: Deploy Infrastructure (Optional)
If you want to redeploy with the new credentials:
1. Go to **Actions** tab
2. Find **"Terraform Apply"** workflow
3. Click **"Run workflow"**
4. Select environment (`development` or `production`)
5. Click **"Run workflow"**

## That's It!

Your existing CI/CD pipeline will automatically use the new credentials for any future deployments.

## Troubleshooting

If the credentials test fails:
- Double-check all secrets are updated correctly
- Verify no extra spaces in secret values
- Ensure session token is complete and hasn't expired

## Next Steps

After updating secrets:
1. ✅ Test credentials via GitHub Actions
2. ✅ Deploy infrastructure if needed
3. ✅ Monitor deployment in Actions tab
4. ✅ Verify AWS resources in console

Your automated cloud infrastructure is ready to deploy with the new credentials! 🚀