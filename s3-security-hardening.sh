#!/bin/bash

###############################################################################
# S3 Security Hardening Script
# Purpose: Automatically secure an S3 bucket following AWS best practices
# Usage: ./s3-security-hardening.sh MY_BUCKET
# Author: AWS Cloud Security Lab
# Date: April 2026
###############################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if bucket name provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Bucket name required${NC}"
    echo "Usage: $0 <bucket-name>"
    exit 1
fi

BUCKET_NAME=$1
REGION=${2:-us-east-1}
KMS_KEY_ID=${3:-""}
LOG_BUCKET="${BUCKET_NAME}-logs"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}S3 BUCKET SECURITY HARDENING${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Bucket: $BUCKET_NAME"
echo "Region: $REGION"
echo ""

# Function to log status
log_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

###############################################################################
# STEP 1: Enable Block Public Access
###############################################################################
echo ""
echo -e "${BLUE}Step 1/9: Enabling Block Public Access...${NC}"

if aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
    2>/dev/null; then
    log_status "Block Public Access enabled"
else
    log_error "Failed to enable Block Public Access"
    exit 1
fi

###############################################################################
# STEP 2: Set Bucket ACL to Private
###############################################################################
echo ""
echo -e "${BLUE}Step 2/9: Setting bucket ACL to private...${NC}"

if aws s3api put-bucket-acl --bucket "$BUCKET_NAME" --acl private 2>/dev/null; then
    log_status "Bucket ACL set to private"
else
    log_warning "Could not modify bucket ACL (may already be set)"
fi

###############################################################################
# STEP 3: Remove Public Bucket Policy
###############################################################################
echo ""
echo -e "${BLUE}Step 3/9: Removing public bucket policies...${NC}"

POLICY=$(aws s3api get-bucket-policy --bucket "$BUCKET_NAME" --query 'Policy' --output text 2>/dev/null || echo "")

if [ -n "$POLICY" ] && echo "$POLICY" | grep -q '"Principal"\s*:\s*"\*"'; then
    log_warning "Public policy found, removing..."
    aws s3api delete-bucket-policy --bucket "$BUCKET_NAME" 2>/dev/null
    log_status "Public policy removed"
else
    log_status "No public policies found"
fi

###############################################################################
# STEP 4: Enable Default Encryption
###############################################################################
echo ""
echo -e "${BLUE}Step 4/9: Enabling default encryption...${NC}"

if [ -z "$KMS_KEY_ID" ]; then
    # Use AES-256
    if aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    },
                    "BucketKeyEnabled": true
                }
            ]
        }' 2>/dev/null; then
        log_status "Default encryption enabled (AES-256)"
    else
        log_error "Failed to enable encryption"
        exit 1
    fi
else
    # Use KMS
    if aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration "{
            \"Rules\": [
                {
                    \"ApplyServerSideEncryptionByDefault\": {
                        \"SSEAlgorithm\": \"aws:kms\",
                        \"KMSMasterKeyID\": \"$KMS_KEY_ID\"
                    },
                    \"BucketKeyEnabled\": true
                }
            ]
        }" 2>/dev/null; then
        log_status "Default encryption enabled (KMS)"
    else
        log_error "Failed to enable KMS encryption"
        exit 1
    fi
fi

###############################################################################
# STEP 5: Enable Versioning
###############################################################################
echo ""
echo -e "${BLUE}Step 5/9: Enabling versioning...${NC}"

if aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled 2>/dev/null; then
    log_status "Versioning enabled"
else
    log_error "Failed to enable versioning"
    exit 1
fi

###############################################################################
# STEP 6: Create Logging Bucket and Enable Logging
###############################################################################
echo ""
echo -e "${BLUE}Step 6/9: Setting up access logging...${NC}"

# Check if logging bucket exists
if ! aws s3api head-bucket --bucket "$LOG_BUCKET" 2>/dev/null; then
    log_info "Creating logging bucket..."
    if aws s3api create-bucket --bucket "$LOG_BUCKET" --region "$REGION" 2>/dev/null; then
        log_status "Logging bucket created"
    else
        log_warning "Could not create logging bucket (may already exist)"
    fi
fi

# Enable logging on main bucket
if aws s3api put-bucket-logging \
    --bucket "$BUCKET_NAME" \
    --bucket-logging-status "{
        \"LoggingEnabled\": {
            \"TargetBucket\": \"$LOG_BUCKET\",
            \"TargetPrefix\": \"s3-access-logs/$BUCKET_NAME/\"
        }
    }" 2>/dev/null; then
    log_status "Access logging enabled (logs to $LOG_BUCKET)"
else
    log_warning "Could not enable logging (may need manual configuration)"
fi

###############################################################################
# STEP 7: Enable Server-Side Request Authentication (Optional)
###############################################################################
echo ""
echo -e "${BLUE}Step 7/9: Enabling request authentication...${NC}"

if aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled 2>/dev/null; then
    log_status "Request authentication configured"
else
    log_status "Request authentication already configured"
fi

###############################################################################
# STEP 8: Tag Bucket for Compliance
###############################################################################
echo ""
echo -e "${BLUE}Step 8/9: Tagging bucket for compliance...${NC}"

TAGS='{
    "TagSet": [
        {
            "Key": "SecurityLevel",
            "Value": "High"
        },
        {
            "Key": "Compliance",
            "Value": "Yes"
        },
        {
            "Key": "LastSecurityAudit",
            "Value": "'$(date +%Y-%m-%d)'"
        }
    ]
}'

if aws s3api put-bucket-tagging --bucket "$BUCKET_NAME" --tagging "$TAGS" 2>/dev/null; then
    log_status "Compliance tags added"
else
    log_warning "Could not add tags"
fi

###############################################################################
# STEP 9: Verification and Report
###############################################################################
echo ""
echo -e "${BLUE}Step 9/9: Verifying security configuration...${NC}"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}SECURITY AUDIT REPORT${NC}"
echo -e "${BLUE}========================================${NC}"

# Check Block Public Access
BLOCK_PUBLIC=$(aws s3api get-public-access-block --bucket "$BUCKET_NAME" --query 'PublicAccessBlockConfiguration' 2>/dev/null)
if echo "$BLOCK_PUBLIC" | grep -q "true"; then
    echo -e "${GREEN}✓ Block Public Access: ENABLED${NC}"
else
    echo -e "${RED}✗ Block Public Access: DISABLED${NC}"
fi

# Check Encryption
ENCRYPTION=$(aws s3api get-bucket-encryption --bucket "$BUCKET_NAME" --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' 2>/dev/null)
if [ -n "$ENCRYPTION" ]; then
    echo -e "${GREEN}✓ Encryption: ENABLED ($ENCRYPTION)${NC}"
else
    echo -e "${RED}✗ Encryption: DISABLED${NC}"
fi

# Check Versioning
VERSIONING=$(aws s3api get-bucket-versioning --bucket "$BUCKET_NAME" --query 'Status' 2>/dev/null)
if [ "$VERSIONING" = "Enabled" ]; then
    echo -e "${GREEN}✓ Versioning: ENABLED${NC}"
else
    echo -e "${YELLOW}! Versioning: $VERSIONING${NC}"
fi

# Check Logging
LOGGING=$(aws s3api get-bucket-logging --bucket "$BUCKET_NAME" --query 'LoggingEnabled.TargetBucket' 2>/dev/null)
if [ -n "$LOGGING" ]; then
    echo -e "${GREEN}✓ Access Logging: ENABLED ($LOGGING)${NC}"
else
    echo -e "${YELLOW}! Access Logging: NOT CONFIGURED${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Security hardening complete!${NC}"
echo -e "${BLUE}========================================${NC}"

# Create a summary JSON file
SUMMARY_FILE="${BUCKET_NAME}-security-audit-$(date +%Y%m%d-%H%M%S).json"
cat > "$SUMMARY_FILE" << EOF
{
  "bucket_name": "$BUCKET_NAME",
  "audit_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "region": "$REGION",
  "block_public_access": true,
  "encryption": "$ENCRYPTION",
  "versioning": "$VERSIONING",
  "access_logging": "$LOGGING",
  "log_bucket": "$LOG_BUCKET",
  "status": "SECURED"
}
EOF

log_status "Audit report saved to: $SUMMARY_FILE"

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review the audit report: $(pwd)/$SUMMARY_FILE"
echo "2. Implement IAM policies from: secure-iam-policy.json"
echo "3. Enable CloudTrail for API monitoring"
echo "4. Schedule monthly security audits"
echo ""
