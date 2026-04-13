"""
AWS Lambda Function - S3 Security Monitoring
Purpose: Continuously monitor S3 buckets for security misconfigurations
Triggers: CloudWatch Events (scheduled) or SNS notifications
Author: AWS Cloud Security Lab
Date: April 2026

Deployment:
  1. Create IAM role with S3 and CloudWatch Logs permissions
  2. Create Lambda function with this code
  3. Add CloudWatch Events trigger (e.g., rate(1 day))
  4. Configure SNS topic for alerts
  5. Test: Invoke function from Lambda console
"""

import json
import boto3
from datetime import datetime
import os

s3_client = boto3.client('s3')
sns_client = boto3.client('sns')
cloudwatch = boto3.client('cloudwatch')

# Configuration
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN', '')
MAX_BUCKET_AGE_DAYS = int(os.environ.get('MAX_BUCKET_AGE_DAYS', '7'))


class S3SecurityAuditor:
    """Audit S3 buckets for security misconfigurations"""

    def __init__(self):
        self.findings = []
        self.buckets_audited = 0
        self.issues_found = 0

    def audit_all_buckets(self):
        """Audit all S3 buckets in the account"""
        try:
            response = s3_client.list_buckets()
            buckets = response.get('Buckets', [])

            for bucket in buckets:
                bucket_name = bucket['Name']
                self.audit_bucket(bucket_name)

        except Exception as e:
            self.findings.append({
                'severity': 'ERROR',
                'bucket': 'GLOBAL',
                'issue': f'Failed to list buckets: {str(e)}'
            })

        return {
            'total_buckets': len(buckets),
            'audited': self.buckets_audited,
            'issues_found': self.issues_found,
            'findings': self.findings
        }

    def audit_bucket(self, bucket_name):
        """Audit a single bucket for security issues"""
        self.buckets_audited += 1
        
        try:
            # Check 1: Block Public Access
            self.check_block_public_access(bucket_name)
            
            # Check 2: Encryption
            self.check_encryption(bucket_name)
            
            # Check 3: Versioning
            self.check_versioning(bucket_name)
            
            # Check 4: Logging
            self.check_logging(bucket_name)
            
            # Check 5: Bucket Policy
            self.check_bucket_policy(bucket_name)
            
            # Check 6: ACL
            self.check_bucket_acl(bucket_name)
            
        except Exception as e:
            self.findings.append({
                'severity': 'ERROR',
                'bucket': bucket_name,
                'issue': f'Audit failed: {str(e)}'
            })
            self.issues_found += 1

    def check_block_public_access(self, bucket_name):
        """Verify Block Public Access is enabled"""
        try:
            response = s3_client.get_public_access_block(Bucket=bucket_name)
            config = response['PublicAccessBlockConfiguration']
            
            if not (config['BlockPublicAcls'] and config['BlockPublicPolicy'] and
                    config['IgnorePublicAcls'] and config['RestrictPublicBuckets']):
                self.findings.append({
                    'severity': 'CRITICAL',
                    'bucket': bucket_name,
                    'check': 'Block Public Access',
                    'issue': 'Not all Block Public Access settings are enabled',
                    'details': config
                })
                self.issues_found += 1
        except s3_client.exceptions.NoSuchPublicAccessBlockConfiguration:
            self.findings.append({
                'severity': 'CRITICAL',
                'bucket': bucket_name,
                'check': 'Block Public Access',
                'issue': 'Block Public Access not configured'
            })
            self.issues_found += 1

    def check_encryption(self, bucket_name):
        """Verify encryption is enabled"""
        try:
            response = s3_client.get_bucket_encryption(Bucket=bucket_name)
            rules = response['ServerSideEncryptionConfiguration']['Rules']
            
            if not rules:
                self.findings.append({
                    'severity': 'HIGH',
                    'bucket': bucket_name,
                    'check': 'Encryption',
                    'issue': 'No encryption rules configured'
                })
                self.issues_found += 1
        except s3_client.exceptions.ServerSideEncryptionConfigurationNotFoundError:
            self.findings.append({
                'severity': 'HIGH',
                'bucket': bucket_name,
                'check': 'Encryption',
                'issue': 'Encryption not enabled'
            })
            self.issues_found += 1

    def check_versioning(self, bucket_name):
        """Verify versioning is enabled"""
        try:
            response = s3_client.get_bucket_versioning(Bucket=bucket_name)
            status = response.get('Status', 'Disabled')
            
            if status != 'Enabled':
                self.findings.append({
                    'severity': 'MEDIUM',
                    'bucket': bucket_name,
                    'check': 'Versioning',
                    'issue': f'Versioning is {status}, should be Enabled'
                })
                self.issues_found += 1
        except Exception as e:
            self.findings.append({
                'severity': 'MEDIUM',
                'bucket': bucket_name,
                'check': 'Versioning',
                'issue': f'Could not verify versioning: {str(e)}'
            })

    def check_logging(self, bucket_name):
        """Verify logging is configured"""
        try:
            response = s3_client.get_bucket_logging(Bucket=bucket_name)
            
            if 'LoggingEnabled' not in response:
                self.findings.append({
                    'severity': 'MEDIUM',
                    'bucket': bucket_name,
                    'check': 'Logging',
                    'issue': 'Access logging not configured'
                })
                self.issues_found += 1
        except Exception as e:
            self.findings.append({
                'severity': 'MEDIUM',
                'bucket': bucket_name,
                'check': 'Logging',
                'issue': f'Could not verify logging: {str(e)}'
            })

    def check_bucket_policy(self, bucket_name):
        """Check for overly permissive bucket policies"""
        try:
            response = s3_client.get_bucket_policy(Bucket=bucket_name)
            policy = json.loads(response['Policy'])
            
            for statement in policy.get('Statement', []):
                if statement.get('Effect') == 'Allow':
                    principal = statement.get('Principal', {})
                    
                    # Check for wildcard principal
                    if principal == '*' or (isinstance(principal, dict) and principal.get('AWS') == '*'):
                        self.findings.append({
                            'severity': 'CRITICAL',
                            'bucket': bucket_name,
                            'check': 'Bucket Policy',
                            'issue': 'Bucket policy allows public access (wildcard principal)'
                        })
                        self.issues_found += 1
                        break
        except s3_client.exceptions.NoSuchBucketPolicy:
            pass  # No policy is OK
        except Exception as e:
            self.findings.append({
                'severity': 'MEDIUM',
                'bucket': bucket_name,
                'check': 'Bucket Policy',
                'issue': f'Could not verify policy: {str(e)}'
            })

    def check_bucket_acl(self, bucket_name):
        """Check for overly permissive ACLs"""
        try:
            response = s3_client.get_bucket_acl(Bucket=bucket_name)
            
            for grant in response.get('Grants', []):
                grantee = grant.get('Grantee', {})
                
                # Check for public read/write
                if grantee.get('Type') == 'Group' and 'AllUsers' in grantee.get('URI', ''):
                    self.findings.append({
                        'severity': 'CRITICAL',
                        'bucket': bucket_name,
                        'check': 'Bucket ACL',
                        'issue': 'Bucket ACL grants public access'
                    })
                    self.issues_found += 1
                    break
        except Exception as e:
            self.findings.append({
                'severity': 'MEDIUM',
                'bucket': bucket_name,
                'check': 'Bucket ACL',
                'issue': f'Could not verify ACL: {str(e)}'
            })


def send_alert(audit_results):
    """Send SNS alert with findings"""
    if not SNS_TOPIC_ARN:
        return
    
    if audit_results['issues_found'] == 0:
        return  # No issues, no need to alert
    
    # Sort findings by severity
    critical = [f for f in audit_results['findings'] if f.get('severity') == 'CRITICAL']
    high = [f for f in audit_results['findings'] if f.get('severity') == 'HIGH']
    medium = [f for f in audit_results['findings'] if f.get('severity') == 'MEDIUM']
    
    message = f"""
S3 Security Audit Results
=========================
Timestamp: {datetime.utcnow().isoformat()}
Buckets Audited: {audit_results['audited']}
Issues Found: {audit_results['issues_found']}

CRITICAL ({len(critical)}):
{json.dumps(critical, indent=2)}

HIGH ({len(high)}):
{json.dumps(high[:5], indent=2)}

MEDIUM ({len(medium)}):
{json.dumps(medium[:5], indent=2)}

Review complete audit results in CloudWatch Logs.
"""
    
    try:
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject='S3 Security Audit Alert',
            Message=message
        )
    except Exception as e:
        print(f"Failed to send SNS alert: {e}")


def publish_metrics(audit_results):
    """Publish metrics to CloudWatch"""
    try:
        cloudwatch.put_metric_data(
            Namespace='S3SecurityAudit',
            MetricData=[
                {
                    'MetricName': 'BucketsAudited',
                    'Value': audit_results['audited'],
                    'Unit': 'Count'
                },
                {
                    'MetricName': 'IssuesFound',
                    'Value': audit_results['issues_found'],
                    'Unit': 'Count'
                }
            ]
        )
    except Exception as e:
        print(f"Failed to publish metrics: {e}")


def lambda_handler(event, context):
    """
    Lambda handler function
    
    Environment Variables:
        - SNS_TOPIC_ARN: SNS topic for alerts
        - MAX_BUCKET_AGE_DAYS: Maximum age for buckets (for warning)
    
    Returns:
        Dictionary with audit results
    """
    
    print("Starting S3 Security Audit...")
    
    auditor = S3SecurityAuditor()
    audit_results = auditor.audit_all_buckets()
    
    # Send alerts if issues found
    send_alert(audit_results)
    
    # Publish metrics
    publish_metrics(audit_results)
    
    # Log results
    print(f"Audit complete: {json.dumps(audit_results, indent=2, default=str)}")
    
    return {
        'statusCode': 200,
        'body': json.dumps(audit_results, default=str)
    }


# For local testing
if __name__ == '__main__':
    result = lambda_handler({}, {})
    print(json.dumps(result, indent=2))
