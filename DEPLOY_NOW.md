# Deployment Trigger

Deployment initiated at: $(Get-Date)

Environment: dev

Status: Ready for deployment

---

To deploy:
1. Go to GitHub Actions
2. Select "Simple Infrastructure Deploy"
3. Click "Run workflow"
4. Choose environment (dev/prod)
5. Click "Run workflow"

The workflow will:
- Initialize Terraform with remote state
- Validate configuration
- Plan infrastructure changes
- Apply changes automatically
- Provide deployment summary with URLs