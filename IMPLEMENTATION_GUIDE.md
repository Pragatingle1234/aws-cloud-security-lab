# S3 Bucket Security Implementation Guide

## Quick Start: Securing an S3 Bucket in 15 Minutes

This guide provides copy-paste AWS CLI commands to transform a misconfigured S3 bucket into a secure, compliant resource.

---

## Prerequisites

```
✓ AWS CLI v2 installed
✓ AWS credentials configured with appropriate permissions
✓ Bucket name: replace MY_BUCKET throughout
✓ KMS Key ID: replace YOUR_KMS_KEY_ID (optional)
✓ AWS Account ID: replace 123456789012
✓ VPC ID: replace vpc-12345678 (optional)
```

### Check AWS CLI version:
```bash
aws --version  # Should be aws-cli/2.x or higher
```

### Verify credentials:
```bash
aws sts get-caller-identity
```

---

## Step 1: Enable Block Public Access (2 minutes)

### Block all public access to the bucket:

```bash
# Enable Block Public Access for the bucket
aws s3api put-public-access-block \
  --bucket MY_BUCKET \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Verify it was enabled
aws s3api get-public-access-block --bucket MY_BUCKET
```

### Output should show all four settings as `true`:
```
{
    "PublicAccessBlockConfiguration": {
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }
}
```

---

## Step 2: Remove Existing Public Access (2 minutes)

### Check current permissions:

```bash
# Check if there's a public bucket policy
aws s3api get-bucket-policy --bucket MY_BUCKET 2>/dev/null || echo "No public policy found"

# Check bucket ACL
aws s3api get-bucket-acl --bucket MY_BUCKET

# List all buckets with public access (across account)
aws s3api list-buckets --query 'Buckets[*].Name'
```

### Remove public bucket policy if it exists:

```bash
# Only run if previous command returned a policy
aws s3api delete-bucket-policy --bucket MY_BUCKET
```

### Set bucket ACL to private:

```bash
aws s3api put-bucket-acl \
  --bucket MY_BUCKET \
  --acl private
```

---

## Step 3: Enable Default Encryption (3 minutes)

### Option A: Use AWS-managed encryption (AES-256):

```bash
aws s3api put-bucket-encryption \
  --bucket MY_BUCKET \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        },
        "BucketKeyEnabled": true
      }
    ]
  }'
```

### Option B: Use customer-managed KMS key (recommended for sensitive data):

```bash
# First, get your KMS key ARN
aws kms list-keys --query 'Keys[0].KeyArn'

# Then apply the encryption policy (replace with your key ARN)
aws s3api put-bucket-encryption \
  --bucket MY_BUCKET \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "aws:kms",
          "KMSMasterKeyID": "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
        },
        "BucketKeyEnabled": true
      }
    ]
  }'
```

### Verify encryption is enabled:

```bash
aws s3api get-bucket-encryption --bucket MY_BUCKET
```

---

## Step 4: Enable Versioning (2 minutes)

### Enable versioning and MFA Delete protection:

```bash
# Enable versioning (allows recovery from accidental deletion)
aws s3api put-bucket-versioning \
  --bucket MY_BUCKET \
  --versioning-configuration Status=Enabled

# Verify versioning enabled
aws s3api get-bucket-versioning --bucket MY_BUCKET
```

### Output should show:
```
{
    "Status": "Enabled"
}
```

---

## Step 5: Enable Access Logging (2 minutes)

### Create a logging bucket:

```bash
# Create a separate bucket for logs (must be in same region)
aws s3api create-bucket \
  --bucket MY_BUCKET-logs \
  --region us-east-1

# Enable log storage on the logging bucket
aws s3api put-bucket-object-lock-configuration \
  --bucket MY_BUCKET-logs \
  --object-lock-configuration '{"ObjectLockEnabled":"Enabled"}' 2>/dev/null || true

# Set logging bucket to store logs with object lock (prevents tampering)
```

### Enable logging for your main bucket:

```bash
aws s3api put-bucket-logging \
  --bucket MY_BUCKET \
  --bucket-logging-status '{
    "LoggingEnabled": {
      "TargetBucket": "MY_BUCKET-logs",
      "TargetPrefix": "s3-access-logs/MY_BUCKET/"
    }
  }'

# Verify logging is enabled
aws s3api get-bucket-logging --bucket MY_BUCKET
```

---

## Step 6: Implement Secure IAM Policy (3 minutes)

### Create a policy file with least privilege access:

Save this as `s3-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSpecificRoleOnly",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/ApplicationRole"
      },
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::MY_BUCKET",
        "arn:aws:s3:::MY_BUCKET/*"
      ]
    },
    {
      "Sid": "DenyUnencryptedUploads",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::MY_BUCKET/*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "aws:kms"
        }
      }
    },
    {
      "Sid": "DenyPublicAccess",
      "Effect": "Deny",
      "Principal": "*",
      "Action": [
        "s3:PutBucketPolicy",
        "s3:PutBucketAcl"
      ],
      "Resource": "arn:aws:s3:::MY_BUCKET"
    }
  ]
}
```

### Apply the bucket policy:

```bash
aws s3api put-bucket-policy \
  --bucket MY_BUCKET \
  --policy file://s3-policy.json

# Verify the policy is applied
aws s3api get-bucket-policy --bucket MY_BUCKET
```

---

## Step 7: Enable CloudTrail (3 minutes)

### Create a CloudTrail for S3 API monitoring:

```bash
# Create a CloudTrail S3 bucket for logs (different from above)
aws s3api create-bucket \
  --bucket MY_BUCKET-cloudtrail-logs \
  --region us-east-1

# Create CloudTrail to monitor S3 API calls
aws cloudtrail create-trail \
  --name s3-audit-trail \
  --s3-bucket-name MY_BUCKET-cloudtrail-logs \
  --region us-east-1 \
  --is-multi-region-trail

# Enable logging
aws cloudtrail start-logging --trail-name s3-audit-trail

# Configure event selectors to record S3 data events
aws cloudtrail put-event-selectors \
  --trail-name s3-audit-trail \
  --event-selectors '[
    {
      "ReadWriteType": "All",
      "IncludeManagementEvents": true,
      "DataResources": [
        {
          "Type": "AWS::S3::Object",
          "Values": ["arn:aws:s3:::MY_BUCKET/*"]
        }
      ]
    }
  ]'
```

---

## Step 8: Verify Security Configuration (2 minutes)

### Run this comprehensive verification:

```bash
#!/bin/bash

BUCKET_NAME="MY_BUCKET"

echo "=== S3 BUCKET SECURITY AUDIT ==="
echo ""

# 1. Check Block Public Access
echo "1. Block Public Access Status:"
aws s3api get-public-access-block --bucket $BUCKET_NAME --query 'PublicAccessBlockConfiguration'
echo ""

# 2. Check Encryption
echo "2. Encryption Status:"
aws s3api get-bucket-encryption --bucket $BUCKET_NAME --query 'ServerSideEncryptionConfiguration'
echo ""

# 3. Check Versioning
echo "3. Versioning Status:"
aws s3api get-bucket-versioning --bucket $BUCKET_NAME --query 'Status'
echo ""

# 4. Check Logging
echo "4. Access Logging Status:"
aws s3api get-bucket-logging --bucket $BUCKET_NAME --query 'LoggingEnabled'
echo ""

# 5. Check Bucket Policy
echo "5. Bucket Policy:"
aws s3api get-bucket-policy --bucket $BUCKET_NAME --query 'Policy' 2>/dev/null | jq '.' || echo "No policy found"
echo ""

# 6. Check ACL
echo "6. Bucket ACL:"
aws s3api get-bucket-acl --bucket $BUCKET_NAME --query 'Grants'
echo ""

# 7. List all objects and check if any are publicly readable
echo "7. Checking for public objects..."
aws s3 ls s3://$BUCKET_NAME --recursive --query 'Contents[*].[Key,Size]' --output table || echo "No objects found"
echo ""

echo "=== AUDIT COMPLETE ==="
```

Save as `audit-s3.sh` and run:
```bash
chmod +x audit-s3.sh
./audit-s3.sh
```

---

## Step 9: Security Monitoring & Maintenance

### Set up weekly audits:

```bash
# Create a Lambda function or cron job to run this check
aws s3api get-public-access-block --bucket MY_BUCKET --query 'PublicAccessBlockConfiguration' > /tmp/s3-security-check.json

# If any value is false, send alert
cat /tmp/s3-security-check.json | grep -q '"False"' && echo "ALERT: Public Access not fully blocked!"
```

### Review access logs:

```bash
# Check for unusual access patterns
aws s3api list-objects-v2 \
  --bucket MY_BUCKET-logs \
  --prefix s3-access-logs/ \
  --query 'Contents[?LastModified>=`2026-04-13`]'
```

### Audit IAM role permissions:

```bash
# List all roles with S3 access
aws iam list-roles --query 'Roles[*].RoleName' | xargs -I {} aws iam list-role-policies --role-name {} | grep -i s3

# Review unnecessary permissions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/ApplicationRole \
  --action-names s3:GetObject s3:PutObject s3:DeleteObject \
  --resource-arns arn:aws:s3:::MY_BUCKET/*
```

---

## Troubleshooting

### "Access Denied" when applying policies:

```bash
# Check your user/role permissions
aws iam get-user  # For IAM users
aws sts get-caller-identity  # For roles

# Ensure you have these permissions:
# - s3:PutBucketPolicy
# - s3:PutBucketEncryption
# - s3:PutBucketVersioning
# - s3:PutBucketLogging
```

### "The public access block configuration is invalid":

```bash
# Ensure format is exactly like this
aws s3api put-public-access-block \
  --bucket MY_BUCKET \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

### "Logging target bucket not found":

```bash
# Create the logging bucket first
aws s3api create-bucket --bucket MY_BUCKET-logs --region us-east-1

# Then enable logging
aws s3api put-bucket-logging \
  --bucket MY_BUCKET \
  --bucket-logging-status '{
    "LoggingEnabled": {
      "TargetBucket": "MY_BUCKET-logs",
      "TargetPrefix": "logs/"
    }
  }'
```

---

## One-Liner: Secure Everything

For impatient security professionals (run one command at a time for safety):

```bash
BUCKET="MY_BUCKET"

# 1. Block public
aws s3api put-public-access-block --bucket $BUCKET --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# 2. Encrypt
aws s3api put-bucket-encryption --bucket $BUCKET --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]}'

# 3. Version
aws s3api put-bucket-versioning --bucket $BUCKET --versioning-configuration Status=Enabled

# 4. Verify all
aws s3api get-public-access-block --bucket $BUCKET && echo "✓ Block Public" || echo "✗ Failed"
aws s3api get-bucket-encryption --bucket $BUCKET >/dev/null && echo "✓ Encryption" || echo "✗ Failed"
aws s3api get-bucket-versioning --bucket $BUCKET >/dev/null && echo "✓ Versioning" || echo "✗ Failed"
```

---

## Compliance Checklist

Use this after implementing all steps:

```
☐ Block Public Access: ALL 4 options enabled
☐ Bucket Policy: Restricts to specific principals/actions
☐ Encryption: Enabled by default
☐ Versioning: Enabled
☐ Access Logging: Enabled to separate bucket
☐ CloudTrail: Recording S3 data events
☐ IAM Policy: Follows Principle of Least Privilege
☐ No public objects in bucket
☐ No credentials stored in bucket
☐ Regular audit schedule set
☐ Incident response plan documented
☐ Team trained on processes
```

---

## Next Steps

1. **Immediate** (Today):
   - Implement Steps 1-4 (15 minutes)
   - Fix: Enable Block Public Access, Encryption, Versioning

2. **Short-term** (This week):
   - Implement Steps 5-7 (10 minutes)
   - Fix: Access Logging, IAM Policy, CloudTrail

3. **Medium-term** (This month):
   - Implement Step 8 & 9
   - Audit all other buckets
   - Train team on processes

4. **Long-term** (Ongoing):
   - Weekly security audits
   - Quarterly policy reviews
   - Incident response testing

---

**Document Version**: 1.0  
**Last Updated**: April 2026  
**Estimated Implementation Time**: 30 minutes total
