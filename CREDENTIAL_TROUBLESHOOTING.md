# 🔧 AWS Credentials Troubleshooting

## Issue: Invalid Security Token

The error "The security token included in the request is invalid" typically means:

1. **Expired Credentials** - AWS Academy/Learner Lab credentials expire
2. **Incorrect Format** - Credentials weren't copied correctly
3. **Wrong Region** - Credentials are for a different region

## Quick Fixes:

### Option 1: Refresh AWS Academy Credentials
If using AWS Academy/Learner Lab:
1. Go back to your AWS Academy course
2. **Stop and restart** the Learner Lab
3. Click "AWS Details" again
4. Copy the **fresh** credentials
5. Run `aws configure` again with new credentials

### Option 2: Check Current Configuration
```bash
# Check what's currently configured
aws configure list

# Check if credentials file exists
type %USERPROFILE%\.aws\credentials
```

### Option 3: Manual Credential Setup
Create/edit the credentials file manually:

**File location**: `C:\Users\[username]\.aws\credentials`

**Format**:
```
[default]
aws_access_key_id = YOUR_ACCESS_KEY_HERE
aws_secret_access_key = YOUR_SECRET_KEY_HERE
```

**Config file**: `C:\Users\[username]\.aws\config`
```
[default]
region = us-west-2
output = json
```

### Option 4: Environment Variables (Alternative)
```powershell
# Clear any existing environment variables first
Remove-Item Env:AWS_ACCESS_KEY_ID -ErrorAction SilentlyContinue
Remove-Item Env:AWS_SECRET_ACCESS_KEY -ErrorAction SilentlyContinue
Remove-Item Env:AWS_SESSION_TOKEN -ErrorAction SilentlyContinue

# Set new ones
$env:AWS_ACCESS_KEY_ID="your-access-key"
$env:AWS_SECRET_ACCESS_KEY="your-secret-key"
$env:AWS_DEFAULT_REGION="us-west-2"

# If using temporary credentials (AWS Academy), also set:
$env:AWS_SESSION_TOKEN="your-session-token"
```

## Test After Each Fix:
```bash
aws sts get-caller-identity
```

You should see your account information without errors.

## Common Issues:

1. **AWS Academy**: Credentials expire every few hours - need to refresh
2. **Copy/Paste**: Extra spaces or missing characters
3. **Session Token**: AWS Academy requires session token (3rd credential)
4. **Region**: Make sure region is set to `us-west-2`

## Next Steps:

1. Try Option 1 first (refresh AWS Academy credentials)
2. Test with `aws sts get-caller-identity`
3. Once working, let me know and I'll continue deployment

---

**Which option would you like to try first?** 🔧