# AWS S3 Misconfiguration Security Lab

## Overview

This lab demonstrates the critical risks of misconfigured Amazon S3 buckets and provides practical solutions using AWS IAM policies and the Principle of Least Privilege. You will learn how attackers exploit S3 misconfigurations and how to properly secure your cloud storage infrastructure.

---

## Table of Contents

1. [Step-by-Step: Creating a Public S3 Bucket](#step-by-step-creating-a-public-s3-bucket)
2. [Risks of Public Exposure](#risks-of-public-exposure)
3. [How Attackers Access Data](#how-attackers-access-data)
4. [Security Fixes](#security-fixes)
5. [Principle of Least Privilege](#principle-of-least-privilege)
6. [Real-World Impact](#real-world-impact)

---

## Step-by-Step: Creating a Public S3 Bucket

### What NOT to Do (Vulnerable Configuration)

#### Step 1: Create an S3 Bucket via AWS Console
```
1. Navigate to AWS Management Console → S3
2. Click "Create Bucket"
3. Enter bucket name (e.g., "my-public-data-bucket-demo")
4. Select AWS Region (e.g., us-east-1)
5. Click "Create Bucket"
```

#### Step 2: Disable Default Security Settings
```
⚠️ DANGEROUS STEPS - DO NOT DO THIS IN PRODUCTION ⚠️

1. Click on the newly created bucket
2. Go to "Permissions" tab
3. Click "Block public access (bucket settings)"
4. Uncheck ALL four options:
   ☐ Block all public access
   ☐ Block public ACLs
   ☐ Block public bucket policies
   ☐ Block public object ownership changes
5. Click "Save" and confirm
```

#### Step 3: Add a Public Access Policy (Vulnerable)
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::my-public-data-bucket-demo/*"
        }
    ]
}
```

#### Step 4: Upload Sensitive Data
```
1. Click "Upload"
2. Add files (e.g., customer_data.csv, database_backup.sql)
3. Click "Upload"
4. Data is NOW PUBLICLY ACCESSIBLE
```

---

## Risks of Public Exposure

### 1. **Data Breach**
- **Scope**: Entire bucket contents readable by anyone on the internet
- **Impact**: Exposure of PII (Personally Identifiable Information), credentials, business data
- **Detection**: Often undetected for months or years

### 2. **Regulatory Violations**
- **GDPR**: €20 million or 4% of annual turnover (whichever is higher)
- **HIPAA**: $1.5 million per violation category per year
- **PCI-DSS**: Card data exposure can result in $5,000-$100,000 fines per incident
- **CCPA**: Up to $7,500 per intentional violation

### 3. **Ransomware Staging Ground**
- Attackers upload malware/ransomware to public buckets
- Served as attack vectors against other systems
- Used for command & control malware infrastructure

### 4. **Credential Exposure**
- AWS Access Keys and Secret Keys stored in plain text
- Database connection strings
- API keys and tokens
- Allows lateral movement within AWS infrastructure

### 5. **Malware Distribution**
- Bucket repurposed to distribute malware
- Your AWS account associated with malicious activity
- Potential criminal liability

### 6. **Cost Implications**
- **Data Exfiltration Charges**: $0.09/GB for data transfer OUT
- Attackers downloading terabytes of data → massive unexpected bills
- DDoS amplification attacks using your bucket

---

## How Attackers Access Data

### Attack Method 1: Direct URL Access
```bash
# Attacker discovers bucket name through:
# - DNS enumeration
# - GitHub code repositories (leaked credentials)
# - Security research
# - Shodan/similar scanning tools

# Direct access to public file:
curl https://my-public-data-bucket-demo.s3.amazonaws.com/customer_data.csv

# Or through S3 website endpoint:
curl http://my-public-data-bucket-demo.s3-website-us-east-1.amazonaws.com/
```

### Attack Method 2: AWS CLI Enumeration
```bash
# Attacker uses publicly available tools to:
# 1. List all objects in bucket
aws s3 ls s3://my-public-data-bucket-demo/ --no-sign-request

# 2. Download all contents
aws s3 sync s3://my-public-data-bucket-demo/ ./downloaded-data/ --no-sign-request

# 3. Search for sensitive files
aws s3 ls s3://my-public-data-bucket-demo/ --recursive --no-sign-request | grep -i "key\|secret\|password\|credential"
```

### Attack Method 3: Automated Scanning
- **Tools**: S3Scanner, Bucket_Finder, BucketCop
- **Techniques**: Dictionary attacks using common naming patterns
  - `company-backup`
  - `company-database`
  - `company-logs`
  - `company-dev`
  - `company-prod`

### Attack Method 4: Hidden File Discovery
```bash
# Attacker searches for common sensitive files:
curl https://my-public-data-bucket-demo.s3.amazonaws.com/.aws/credentials
curl https://my-public-data-bucket-demo.s3.amazonaws.com/.env
curl https://my-public-data-bucket-demo.s3.amazonaws.com/backup.sql
curl https://my-public-data-bucket-demo.s3.amazonaws.com/config.json
```

---

## Security Fixes

### Fix 1: Enable Block Public Access (Foundational)

**AWS Console Steps:**
```
1. Go to S3 → Select Bucket
2. Permissions → Block public access (bucket settings)
3. ENABLE all four options:
   ✓ Block all public access
   ✓ Block public ACLs
   ✓ Block public bucket policies
   ✓ Block public object ownership changes
4. Click "Save"
```

**AWS CLI:**
```bash
aws s3api put-public-access-block \
  --bucket my-secure-bucket \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

### Fix 2: Implement Secure IAM Policy

**Replace the public policy with:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowOnlySpecificRole",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/ApplicationRole"
      },
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-secure-bucket",
        "arn:aws:s3:::my-secure-bucket/*"
      ]
    }
  ]
}
```

**AWS CLI:**
```bash
aws s3api put-bucket-policy --bucket my-secure-bucket --policy file://policy.json
```

### Fix 3: Enable Versioning & MFA Delete

```bash
# Enable versioning (allows recovery from accidental deletion)
aws s3api put-bucket-versioning \
  --bucket my-secure-bucket \
  --versioning-configuration Status=Enabled

# Enable MFA requirement for deletion (prevents unauthorized data removal)
aws s3api put-bucket-versioning \
  --bucket my-secure-bucket \
  --versioning-configuration Status=Enabled,MFADelete=Enabled
```

### Fix 4: Enable Server-Side Encryption

**AWS CLI:**
```bash
# Apply default encryption (AES-256)
aws s3api put-bucket-encryption \
  --bucket my-secure-bucket \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'

# Or use customer-managed KMS key (more control)
aws s3api put-bucket-encryption \
  --bucket my-secure-bucket \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "aws:kms",
          "KMSMasterKeyID": "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
        }
      }
    ]
  }'
```

### Fix 5: Enable Access Logging

```bash
# Create logging bucket first
aws s3api create-bucket --bucket my-secure-bucket-logs

# Enable logging on main bucket
aws s3api put-bucket-logging \
  --bucket my-secure-bucket \
  --bucket-logging-status '{
    "LoggingEnabled": {
      "TargetBucket": "my-secure-bucket-logs",
      "TargetPrefix": "s3-access-logs/"
    }
  }'
```

### Fix 6: Enable CloudTrail for API Monitoring

```bash
# Log all S3 API calls to CloudTrail
aws cloudtrail put-event-selectors \
  --trail-name s3-trail \
  --event-selectors '[{
    "ReadWriteType": "All",
    "IncludeManagementEvents": true,
    "DataResources": [{
      "Type": "AWS::S3::Object",
      "Values": ["arn:aws:s3:::my-secure-bucket/*"]
    }]
  }]'
```

---

## Principle of Least Privilege

### What is Least Privilege?

**Definition**: Grant users, roles, and services the **minimum permissions needed** to perform their specific function, nothing more.

### The 80/20 Rule

```
❌ WRONG (80% of teams do this):
   - Grant S3FullAccess or Administrator role
   - "We'll manage it later"
   - Result: One compromised credential = full AWS compromise

✅ RIGHT (Least Privilege):
   - Grant only GetObject on specific bucket
   - Grant only ListBucket on specific bucket
   - Scope to specific IP ranges or VPCs
```

### Implementation Strategy

#### 1. **Identify Required Actions**
```
User/Service: EC2 Application Server
Required S3 Actions:
  ✓ s3:GetObject (read files)
  ✓ s3:ListBucket (list files)
  ✗ s3:DeleteObject (never needed)
  ✗ s3:PutObject (never needed)
  ✗ s3:PutBucketPolicy (never needed)
```

#### 2. **Scope to Specific Resources**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadAppData",
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::app-data-bucket/app-files/*"
    },
    {
      "Sid": "ListBucket",
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::app-data-bucket",
      "Condition": {
        "StringLike": {
          "s3:prefix": ["app-files/*"]
        }
      }
    }
  ]
}
```

#### 3. **Add Conditions for Extra Security**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadOnlyFromVPC",
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::app-data-bucket/*",
      "Condition": {
        "StringEquals": {
          "aws:SourceVpc": "vpc-12345678"
        },
        "IpAddress": {
          "aws:SourceIp": ["10.0.1.0/24"]
        }
      }
    }
  ]
}
```

#### 4. **Regular Audits**
```bash
# List all permissions (identify excessive grants)
aws iam get-user-policy --user-name app-user --policy-name s3-policy

# Use AWS Access Analyzer to find unused permissions
aws accessanalyzer validate-policy \
  --policy-document file://policy.json \
  --policy-type IDENTITY_POLICY
```

### Principle of Least Privilege Benefits

| Benefit | Impact |
|---------|--------|
| **Reduced Blast Radius** | Compromised credential limited to one service/bucket |
| **Compliance** | Meets GDPR, HIPAA, PCI-DSS, SOC2 requirements |
| **Audit Trail** | Easy to track who did what |
| **Faster Incident Response** | Limited scope = easier containment |
| **Cost Control** | Prevents accidental resource creation/deletion |

---

## Real-World Impact

### Case Study 1: Capital One Data Breach (2019)
- **Exposure**: 106 million customers' PII
- **Root Cause**: Misconfigured S3 bucket + overprivileged IAM role
- **Impact**: $80 million settlement + regulatory fines
- **Lesson**: Proper IAM policies would have prevented this

### Case Study 2: AWS S3 Data Leaks
- **Trend**: Hundreds of public S3 buckets found annually
- **Data Types**: Millions of medical records, financial data, personal photos
- **Average Time to Discovery**: 6-18 months (often found by security researchers)
- **Average Cost**: $4.24M per breach (IBM 2021 Data Breach Report)

### Case Study 3: Facebook Bug Bounty Hunters
- Researchers discovered **public S3 buckets** containing:
  - AWS credentials
  - Database backups
  - Deployment scripts
  - Customer PII
- Found through: GitHub code leaks, DNS enumeration

### Why Cloud Security is Critical

#### 1. **Speed of Impact**
```
Traditional Data Center:
  - Physical security needed
  - Network segmentation
  - Multiple layers of protection

Cloud Environment:
  - One misconfiguration
  - Instantly accessible worldwide
  - No physical barriers
  - Can impact millions in minutes
```

#### 2. **Attacker Motivation**
- **Ransomware Gangs**: Target misconfigured cloud storage
- **Nation States**: Exploit cloud misconfigurations for espionage
- **Competitors**: Access to business strategies
- **Cryptominers**: Use your resources for profit

#### 3. **Compliance Landscape**
- **GDPR**: Mandatory notification within 72 hours of breach
- **CCPA**: Consumer right to know what data was accessed
- **HIPAA**: Covered entities must report breaches affecting >500 individuals
- **PCI-DSS**: Card data leaks = $5,000-$100,000 per incident

#### 4. **Business Continuity**
- **Ransomware**: Attacker deletes or encrypts your backups
- **Data Retention**: Attackers modify object retention policies
- **Availability**: Bucket used for DDoS amplification

---

## Security Checklist

Use this checklist to audit your S3 buckets:

```
☐ Block Public Access ENABLED (all 4 settings)
☐ Bucket policy restricts to specific IAM roles
☐ No wildcard (*) principals in policy
☐ Encryption enabled (AES-256 or KMS)
☐ Versioning enabled
☐ MFA Delete enabled
☐ Access Logging enabled
☐ CloudTrail logging enabled
☐ Bucket lifecycle policies configured
☐ No credentials stored in bucket
☐ No private keys in bucket
☐ Regular security audits scheduled
☐ IAM policy follows Least Privilege principle
☐ VPC endpoints used for private access
☐ Cross-account access uses STS AssumeRole
```

---

## Additional Resources

- **AWS S3 Security Best Practices**: https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html
- **IAM Best Practices**: https://docs.aws.amazon.com/IAM/latest/userguide/best-practices.html
- **S3 Security Scanner**: https://github.com/jordanpotti/AWSBucketDump
- **AWS Security Hub**: Monitor compliance automatically

---

## Next Steps

1. Audit current S3 buckets using the checklist above
2. Implement the security fixes in order of priority
3. Use AWS Config rules to enforce S3 security
4. Enable AWS Security Hub for continuous monitoring
5. Train your team on cloud security best practices

---

## Contact & Support

For questions about this lab or AWS security concerns, contact your security team or AWS support.

**Last Updated**: April 2026
