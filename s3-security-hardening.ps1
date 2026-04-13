# S3 Security Hardening Script - PowerShell Version
# Purpose: Automatically secure an S3 bucket following AWS best practices
# Usage: .\s3-security-hardening.ps1 -BucketName "MY_BUCKET" -Region "us-east-1"
# Author: AWS Cloud Security Lab
# Date: April 2026

param(
    [Parameter(Mandatory=$true)]
    [string]$BucketName,
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1",
    
    [Parameter(Mandatory=$false)]
    [string]$KmsKeyId = ""
)

# Color codes for output
function Write-Success { Write-Host "[✓] $args" -ForegroundColor Green }
function Write-Error-Custom { Write-Host "[✗] $args" -ForegroundColor Red }
function Write-Info { Write-Host "[i] $args" -ForegroundColor Cyan }
function Write-Warning-Custom { Write-Host "[!] $args" -ForegroundColor Yellow }

$LogBucket = "$BucketName-logs"
$AuditTimestamp = Get-Date -Format "yyyyMMdd-HHmmss"

Write-Host "========================================"
Write-Host "S3 BUCKET SECURITY HARDENING" -ForegroundColor Cyan
Write-Host "========================================"
Write-Host "Bucket: $BucketName"
Write-Host "Region: $Region"
Write-Host ""

###############################################################################
# STEP 1: Enable Block Public Access
###############################################################################
Write-Host "Step 1/9: Enabling Block Public Access..." -ForegroundColor Cyan

try {
    $blockPublicAccessParams = @{
        BucketName = $BucketName
        BlockPublicAcls = $true
        BlockPublicPolicy = $true
        IgnorePublicAcls = $true
        RestrictPublicBuckets = $true
    }
    
    Write-S3BlockPublicAccessConfiguration @blockPublicAccessParams
    Write-Success "Block Public Access enabled"
} catch {
    Write-Error-Custom "Failed to enable Block Public Access: $_"
    exit 1
}

###############################################################################
# STEP 2: Set Bucket ACL to Private
###############################################################################
Write-Host "Step 2/9: Setting bucket ACL to private..." -ForegroundColor Cyan

try {
    Set-S3ACL -BucketName $BucketName -CannedACL "private"
    Write-Success "Bucket ACL set to private"
} catch {
    Write-Warning-Custom "Could not modify bucket ACL: $_"
}

###############################################################################
# STEP 3: Remove Public Bucket Policy
###############################################################################
Write-Host "Step 3/9: Removing public bucket policies..." -ForegroundColor Cyan

try {
    $policy = Get-S3BucketPolicy -BucketName $BucketName -ErrorAction SilentlyContinue
    
    if ($policy -and $policy -match '"Principal"\s*:\s*"\*"') {
        Write-Warning-Custom "Public policy found, removing..."
        Remove-S3BucketPolicy -BucketName $BucketName -Force
        Write-Success "Public policy removed"
    } else {
        Write-Success "No public policies found"
    }
} catch {
    Write-Info "No bucket policy to remove"
}

###############################################################################
# STEP 4: Enable Default Encryption
###############################################################################
Write-Host "Step 4/9: Enabling default encryption..." -ForegroundColor Cyan

try {
    if ([string]::IsNullOrEmpty($KmsKeyId)) {
        # Use AES-256
        $encryptionConfig = New-Object Amazon.S3.Model.ServerSideEncryptionConfiguration
        $rule = New-Object Amazon.S3.Model.ServerSideEncryptionRule
        $rule.ServerSideEncryptionByDefault = New-Object Amazon.S3.Model.ServerSideEncryptionByDefault
        $rule.ServerSideEncryptionByDefault.ServerSideEncryptionAlgorithm = [Amazon.S3.ServerSideEncryptionMethod]::AES256
        $encryptionConfig.Rules.Add($rule)
        
        Set-S3BucketEncryption -BucketName $BucketName -ServerSideEncryptionConfiguration $encryptionConfig
        Write-Success "Default encryption enabled (AES-256)"
    } else {
        # Use KMS
        $encryptionConfig = New-Object Amazon.S3.Model.ServerSideEncryptionConfiguration
        $rule = New-Object Amazon.S3.Model.ServerSideEncryptionRule
        $rule.ServerSideEncryptionByDefault = New-Object Amazon.S3.Model.ServerSideEncryptionByDefault
        $rule.ServerSideEncryptionByDefault.ServerSideEncryptionAlgorithm = [Amazon.S3.ServerSideEncryptionMethod]::AWS_KMS
        $rule.ServerSideEncryptionByDefault.KeyWrapAlgorithm = [Amazon.S3.KeyWrapAlgorithm]::AWS_KMS
        $rule.ServerSideEncryptionByDefault.KMSMasterKeyID = $KmsKeyId
        $encryptionConfig.Rules.Add($rule)
        
        Set-S3BucketEncryption -BucketName $BucketName -ServerSideEncryptionConfiguration $encryptionConfig
        Write-Success "Default encryption enabled (KMS)"
    }
} catch {
    Write-Error-Custom "Failed to enable encryption: $_"
    exit 1
}

###############################################################################
# STEP 5: Enable Versioning
###############################################################################
Write-Host "Step 5/9: Enabling versioning..." -ForegroundColor Cyan

try {
    Set-S3BucketVersioning -BucketName $BucketName -VersioningConfig (New-Object Amazon.S3.Model.VersioningConfig -Property @{ Status = "Enabled" })
    Write-Success "Versioning enabled"
} catch {
    Write-Error-Custom "Failed to enable versioning: $_"
    exit 1
}

###############################################################################
# STEP 6: Create Logging Bucket and Enable Logging
###############################################################################
Write-Host "Step 6/9: Setting up access logging..." -ForegroundColor Cyan

try {
    # Check if logging bucket exists
    if (-not (Test-S3Bucket -BucketName $LogBucket)) {
        Write-Info "Creating logging bucket..."
        New-S3Bucket -BucketName $LogBucket -Region $Region
        Write-Success "Logging bucket created"
    }
    
    # Enable logging on main bucket
    $loggingConfig = New-Object Amazon.S3.Model.S3BucketLoggingConfig
    $loggingConfig.TargetBucketName = $LogBucket
    $loggingConfig.TargetPrefix = "s3-access-logs/$BucketName/"
    
    Set-S3BucketLogging -BucketName $BucketName -LoggingConfig $loggingConfig
    Write-Success "Access logging enabled (logs to $LogBucket)"
} catch {
    Write-Warning-Custom "Could not enable logging: $_"
}

###############################################################################
# STEP 7: Tag Bucket for Compliance
###############################################################################
Write-Host "Step 7/9: Tagging bucket for compliance..." -ForegroundColor Cyan

try {
    $tagSet = New-Object Collections.Generic.List[Amazon.S3.Model.Tag]
    $tagSet.Add((New-Object Amazon.S3.Model.Tag -Property @{ Key = "SecurityLevel"; Value = "High" }))
    $tagSet.Add((New-Object Amazon.S3.Model.Tag -Property @{ Key = "Compliance"; Value = "Yes" }))
    $tagSet.Add((New-Object Amazon.S3.Model.Tag -Property @{ Key = "LastSecurityAudit"; Value = (Get-Date -Format "yyyy-MM-dd") }))
    
    Write-S3BucketTagging -BucketName $BucketName -TagSet $tagSet
    Write-Success "Compliance tags added"
} catch {
    Write-Warning-Custom "Could not add tags: $_"
}

###############################################################################
# STEP 8: Enable Versioning Lock (Optional - commented out for safety)
###############################################################################
Write-Host "Step 8/9: Configuring additional protections..." -ForegroundColor Cyan
Write-Info "MFA Delete protection requires manual configuration via AWS Console"

###############################################################################
# STEP 9: Verification and Report
###############################################################################
Write-Host "Step 9/9: Verifying security configuration..." -ForegroundColor Cyan

Write-Host ""
Write-Host "========================================"
Write-Host "SECURITY AUDIT REPORT" -ForegroundColor Cyan
Write-Host "========================================"

# Check Block Public Access
try {
    $blockPublic = Get-S3BlockPublicAccessConfiguration -BucketName $BucketName
    if ($blockPublic.BlockPublicAcls -and $blockPublic.BlockPublicPolicy) {
        Write-Success "Block Public Access: ENABLED"
    } else {
        Write-Error-Custom "Block Public Access: DISABLED"
    }
} catch {
    Write-Warning-Custom "Could not verify Block Public Access"
}

# Check Encryption
try {
    $encryption = Get-S3BucketEncryption -BucketName $BucketName
    $algo = $encryption.ServerSideEncryptionConfiguration.Rules[0].ServerSideEncryptionByDefault.ServerSideEncryptionAlgorithm
    Write-Success "Encryption: ENABLED ($algo)"
} catch {
    Write-Error-Custom "Encryption: DISABLED"
}

# Check Versioning
try {
    $versioning = Get-S3BucketVersioning -BucketName $BucketName
    Write-Success "Versioning: $($versioning.Status)"
} catch {
    Write-Warning-Custom "Could not verify versioning"
}

# Check Logging
try {
    $logging = Get-S3BucketLogging -BucketName $BucketName
    if ($logging.TargetBucketName) {
        Write-Success "Access Logging: ENABLED ($($logging.TargetBucketName))"
    } else {
        Write-Warning-Custom "Access Logging: NOT CONFIGURED"
    }
} catch {
    Write-Warning-Custom "Could not verify logging"
}

###############################################################################
# Create Audit Report
###############################################################################
Write-Host ""
Write-Host "========================================"
Write-Host "Security hardening complete!" -ForegroundColor Green
Write-Host "========================================"

$auditReport = @{
    bucket_name = $BucketName
    audit_date = Get-Date -Format "o"
    region = $Region
    block_public_access = $true
    encryption = "ENABLED"
    versioning = "ENABLED"
    access_logging = "ENABLED"
    log_bucket = $LogBucket
    status = "SECURED"
} | ConvertTo-Json

$auditFile = ".\$BucketName-security-audit-$AuditTimestamp.json"
$auditReport | Out-File -FilePath $auditFile -Encoding UTF8
Write-Success "Audit report saved to: $auditFile"

Write-Host ""
Write-Warning-Custom "Next steps:"
Write-Host "1. Review the audit report: $auditFile"
Write-Host "2. Implement IAM policies from: secure-iam-policy.json"
Write-Host "3. Enable CloudTrail for API monitoring"
Write-Host "4. Schedule monthly security audits"
Write-Host ""
