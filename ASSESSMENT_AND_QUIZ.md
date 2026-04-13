# AWS S3 Cloud Security Assessment
# Purpose: Test knowledge of S3 security best practices
# Format: 50 questions with answers and explanations
# Difficulty: Beginner to Advanced
# Estimated Time: 1.5 hours

---

## SECTION 1: BASICS (Questions 1-10)

### Question 1: Public S3 Bucket Risk
What is the PRIMARY risk of having a public S3 bucket without proper controls?

A) Increased storage costs  
B) Data exposure to anyone on the internet  
C) Slower performance  
D) Higher AWS support bills  

**Answer: B** - Data exposure to anyone on the internet

**Explanation:** Public S3 buckets are accessible globally via direct URL or AWS CLI without authentication. This allows attackers to read, modify, or download sensitive data. Storage costs and performance are not directly affected by public access.

**Related Section:** README.md - "How Attackers Access Data"

---

### Question 2: Block Public Access
Which of these is NOT a Block Public Access setting?

A) Block public ACLs  
B) Block public bucket policies  
C) Block encryption  
D) Restrict public buckets  

**Answer: C** - Block encryption

**Explanation:** The four Block Public Access settings are:
1. Block public ACLs
2. Block public bucket policies
3. Ignore public ACLs
4. Restrict public buckets

Block encryption is a separate setting, not part of Block Public Access.

**Related Section:** IMPLEMENTATION_GUIDE.md - "Step 1: Enable Block Public Access"

---

### Question 3: Encryption Algorithms
AWS S3 supports which of these encryption algorithms? (Select all that apply)

A) AES-256  
B) RSA-2048  
C) AWS KMS (customer-managed keys)  
D) DES (Data Encryption Standard)  

**Answer: A and C** - AES-256 and AWS KMS

**Explanation:**
- **AES-256**: AWS-managed encryption (S3 controls keys)
- **AWS KMS**: Customer-managed keys (you control via KMS)
- **RSA-2048**: Used for key exchange, not S3 object encryption
- **DES**: Legacy, insecure, not supported by AWS

**Related Section:** README.md - "Fix 4: Enable Server-Side Encryption"

---

### Question 4: IAM Principle of Least Privilege
What does Principle of Least Privilege mean?

A) Give all users admin access to simplify management  
B) Grant only the minimum permissions needed to perform a specific task  
C) Require approval for any S3 access  
D) Block all access by default (never allow anything)  

**Answer: B** - Grant only the minimum permissions needed to perform a specific task

**Explanation:** PoLP means granting the minimum permissions necessary. This reduces risk by limiting damage if credentials are compromised. It's different from blocking everything (which prevents work) or giving everyone admin access (which increases risk).

**Related Section:** README.md - "Principle of Least Privilege"

---

### Question 5: Versioning Benefit
What is the PRIMARY benefit of enabling S3 bucket versioning?

A) Reduces storage costs  
B) Improves upload performance  
C) Allows recovery of deleted or modified objects  
D) Encrypts all objects automatically  

**Answer: C** - Allows recovery of deleted or modified objects

**Explanation:** Versioning maintains multiple versions of objects. If an object is deleted or accidentally modified, you can restore a previous version. This is critical for ransomware protection and accidental data loss.

**Related Section:** IMPLEMENTATION_GUIDE.md - "Step 5: Enable Versioning"

---

### Question 6: Access Logging Purpose
Why should you enable S3 access logging?

A) To track who accessed which objects and when  
B) To automatically delete old objects  
C) To encrypt objects in transit  
D) To improve read performance  

**Answer: A** - To track who accessed which objects and when

**Explanation:** S3 access logs record every request to your bucket (who, what, when). This creates an audit trail for compliance and incident investigation. Log storage can help identify suspicious patterns or unauthorized access.

**Related Section:** IMPLEMENTATION_GUIDE.md - "Step 6: Enable Access Logging"

---

### Question 7: Bucket Policy vs. IAM Policy
What is the difference between a bucket policy and an IAM policy?

A) They do the same thing, just different naming  
B) Bucket policies control bucket-level access; IAM policies control user permissions  
C) Bucket policies are automatically applied; IAM policies must be manually activated  
D) Bucket policies only work for public buckets  

**Answer: B** - Bucket policies control bucket-level access; IAM policies control user permissions

**Explanation:**
- **IAM Policy**: Attached to users/roles; controls what they can do across AWS
- **Bucket Policy**: Attached to bucket; controls who can access that specific bucket and how

Both are needed for comprehensive access control.

**Related Section:** iam-policy-scenarios.json - Various scenarios

---

### Question 8: Wildcard (*) in Principal
In an S3 bucket policy, what does Principal: "*" mean?

A) The bucket owner only  
B) Any authenticated AWS user  
C) Anyone on the internet (authenticated or not)  
D) No one (access denied)  

**Answer: C** - Anyone on the internet (authenticated or not)

**Explanation:** "Principal": "*" grants access to the entire world. Combined with an Allow statement, this makes a bucket public. This should be avoided except in very specific cases (like public websites).

**Related Section:** secure-iam-policy.json - "DenyPublicAccess"

---

### Question 9: MFA Delete Protection
What does MFA Delete protection do?

A) Requires multi-factor authentication to upload objects  
B) Requires multi-factor authentication to delete object versions  
C) Encrypts all objects with multi-factor encryption  
D) Prevents deletion but doesn't require MFA  

**Answer: B** - Requires multi-factor authentication to delete object versions

**Explanation:** MFA Delete protection is a double-click for ransomware defense. Even if an attacker gains access, they cannot delete versioned backups without the MFA device. This requires root user account setup.

**Related Section:** IMPLEMENTATION_GUIDE.md - "Fix 3: Enable Versioning & MFA Delete"

---

### Question 10: Cost of Data Breach
According to the IBM 2021 study, what is the average cost of a data breach?

A) $500K - $1M  
B) $1M - $2M  
C) $4.24M  
D) $10M+  

**Answer: C** - $4.24M

**Explanation:** The IBM Cost of Data Breach study shows the average cost is $4.24M, including regulatory fines, legal costs, notification, and business impact.

**Related Section:** SECURITY_RISKS_AND_IMPACT.md - "Financial Impact"

---

## SECTION 2: ATTACKS & THREATS (Questions 11-20)

### Question 11: S3 Bucket Enumeration Attack
An attacker uses `aws s3 ls s3://company-backup --no-sign-request` to list your bucket. What is the No-Sign-Request flag doing?

A) Asking for permission to list the bucket  
B) Attempting to access without AWS credentials  
C) Signing the request with the attacker's credentials  
D) Verifying the attacker's identity  

**Answer: B** - Attempting to access without AWS credentials

**Explanation:** The `--no-sign-request` flag tries to access the bucket as an unauthenticated user. If the bucket is public or allows unauthenticated ListBucket, the command succeeds.

**Related Section:** README.md - "How Attackers Access Data - Attack Method 2"

---

### Question 12: Capital One Breach Root Cause
What was the root cause of the Capital One data breach (2019)?

A) Weak passwords  
B) Misconfigured S3 bucket + overprivileged EC2 IAM role  
C) Ransomware attack  
D) Employee negligence  

**Answer: B** - Misconfigured S3 bucket + overprivileged EC2 IAM role

**Explanation:** An EC2 instance had an IAM role that could access the misconfigured S3 bucket. The attacker compromised the instance and used its role to access 106 million customer records. This led to an $80M settlement.

**Related Section:** SECURITY_RISKS_AND_IMPACT.md - "Case Study 1: Capital One"

---

### Question 13: Attack Vector for Credentials
Which of these is less likely to expose AWS credentials in an S3 bucket?

A) Accidentally committing .env files to GitHub  
B) Storing credentials in plain text in the bucket  
C) Using IAM roles instead of storing credentials  
D) Backup files containing exported credentials  

**Answer: C** - Using IAM roles instead of storing credentials

**Explanation:** IAM roles are automatically rotated and don't require storing credentials. Storing credentials in .env files, plain text, or backups is dangerous if the bucket is compromised.

**Related Section:** README.md - "Risk of Public Exposure - Credential Exposure"

---

### Question 14: Ransomware Attack Pattern
In a ransomware attack involving S3, which of these steps is MOST damaging?

A) Encrypting objects so they can't be read  
B) Deleting all object versions and backups  
C) Changing the bucket policy to make it public  
D) Downloading a copy of the data  

**Answer: B** - Deleting all object versions and backups

**Explanation:** If backups are deleted (including versions), the attacker can demand ransom knowing you can't recover from backups. Modern ransomware specifically targets backup systems. This is why versioning, MFA delete, and separate backup storage are critical.

**Related Section:** README.md - "Risk of Public Exposure - Ransomware Staging"

---

### Question 15: Bucket Discovery Method
How do attackers typically discover S3 buckets?

A) AWS CLI requires credentials, so attackers can't find buckets  
B) Tanner names, GitHub commits, DNS enumeration, automated scanning  
C) Buckets are not discoverable; only the bucket owner knows the name  
D) Attackers must be invited by the bucket owner  

**Answer: B** - Tanner names, GitHub commits, DNS enumeration, automated scanning

**Explanation:** Attackers use:
- Common naming patterns (company-backup, company-prod, etc.)
- GitHub search for hardcoded bucket names
- DNS enumeration of S3 endpoints
- Automated scanners that try common names

Bucket names are bucket-scoped, not completely secret.

**Related Section:** README.md - "How Attackers Access Data - Attack Method 3"

---

### Question 16: Data Exfiltration Charges
Your S3 bucket is compromised and 500GB of data is downloaded. What AWS charges might apply?

A) Only data stored (no charges for downloads)  
B) $0.09/GB for data transfer out = $45  
C) $0.09/GB for 500GB = $45 (but could be much higher if multiple downloads)  
D) No charges; AWS includes unlimited data transfer  

**Answer: C** - $0.09/GB for 500GB = $45 (but could be much higher)

**Explanation:** S3 charges $0.09/GB for data transfer OUT to the internet. If attackers download 1TB, that's $90. Large breaches can result in thousands in unexpected charges.

**Related Section:** README.md - "Risk of Public Exposure - Cost Implications"

---

### Question 17: Policy Bypassing
An attacker sees a bucket policy with Principal: "AWS": "arn:aws:iam::123456789012:role/ApplicationRole". Can they still access the bucket?

A) Yes, they can still access if they compromise the ApplicationRole  
B) No, the bucket is now secure  
C) Only the region owner can access  
D) The policy doesn't restrict anything  

**Answer: A** - Yes, they can still access if they compromise the ApplicationRole

**Explanation:** The bucket policy allows the ApplicationRole to access. If an attacker compromises any credentials with that role (including from the EC2 instance using that role), they can access the bucket. Anothe layer of defense is needed (encryption, encryption key restrictions).

**Related Section:** secure-iam-policy.json - Layered security approach

---

### Question 18: Malware Distribution Risk
If your public S3 bucket is used for malware distribution, what could happen?

A) Just a PR problem, nothing technical  
B) Your AWS account could be blacklisted, rate-limited, or suspended  
C) Only the attacker's account is affected  
D) AWS automatically blocks malware uploads  

**Answer: B** - Your AWS account could be blacklisted, rate-limited, or suspended

**Explanation:** AWS actively monitors for abuse. If your bucket distributes malware, AWS may:
- Blacklist your account
- Rate-limit your API calls
- Suspend your account permanently
- Put you on law enforcement watchlists

This is a serious incident.

**Related Section:** README.md - "Risk of Public Exposure - Malware Distribution"

---

### Question 19: Regulatory Fine Example
Under GDPR, if a company exposes personal data of EU citizens through an S3 bucket, what is the maximum fine?

A) €5 million or 2% of annual turnover  
B) €20 million or 4% of annual turnover  
C) €50 million  
D) Depends on company size only  

**Answer: B** - €20 million or 4% of annual turnover

**Explanation:** GDPR has tiered penalties:
- **Tier 1**: Up to €10M or 2% (administrative violations)
- **Tier 2**: Up to €20M or 4% (data protection violations like breaches)

Amazon was fined €746M for GDPR violations.

**Related Section:** SECURITY_RISKS_AND_IMPACT.md - "Regulatory Consequences"

---

### Question 20: Verizon Breach
In the Verizon 2021 S3 breach, how many customer records were exposed?

A) 1 million  
B) 5 million  
C) 20 million  
D) 100+ million  

**Answer: C** - 20 million

**Explanation:** Verizon Business exposed 20 million customer records in a misconfigured S3 bucket. This included customer names, phone numbers, account numbers, and detailed call logs. The breach was discovered by security researchers.

**Related Section:** SECURITY_RISKS_AND_IMPACT.md - "Documented Data Leaks - Verizon"

---

## SECTION 3: DEFENSE & REMEDIATION (Questions 21-35)

### Question 21: Defense Layering
What is "defense in depth" for S3?

A) A single strong policy is enough  
B) Multiple overlapping security controls (Block Access, Encryption, IAM, Logging)  
C) Only focusing on one threat  
D) Defense is not needed if you're careful  

**Answer: B** - Multiple overlapping security controls

**Explanation:** Defense in depth means multiple layers:
1. Block Public Access
2. Encryption
3. IAM policies
4. Access Logging
5. CloudTrail
6. Versioning/MFA Delete

Even if one layer fails, others still protect you.

**Related Section:** Entire documentation emphasizes this approach

---

### Question 22: Quick Security Fix Priority
If you have 1 hour to secure an existing S3 bucket, what should you do FIRST?

A) Set complex bucket naming schemes  
B) Enable Block Public Access  
C) Configure Terraform templates  
D) Write audit reports  

**Answer: B** - Enable Block Public Access

**Explanation:** Block Public Access is the quickest, highest-impact fix (2 minutes). It prevents public access regardless of other misconfiguration. It should be the FIRST step in any remediation.

**Related Section:** IMPLEMENTATION_GUIDE.md - "Step 1"

---

### Question 23: Encryption Type Decision
When should you use KMS encryption instead of AES-256?

A) Always use AES-256, it's simpler  
B) Use KMS for sensitive data; AES-256 for non-sensitive  
C) KMS is only for databases  
D) There's no difference, use either  

**Answer: B** - Use KMS for sensitive data; AES-256 for non-sensitive

**Explanation:**
- **AES-256**: Simpler, fewer moving parts, fast, good for most workloads
- **KMS**: More control, audit trail of key usage, rotation, better for compliance/sensitive data

Choose based on sensitivity and regulatory requirements.

**Related Section:** IMPLEMENTATION_GUIDE.md - "Step 4: Enable Encryption"

---

### Question 24: Backup Strategy
For critical data, what is the recommended backup strategy?

A) Store backups in the same bucket  
B) Store in different bucket, same region  
C) Store in different account, different region, with versioning + MFA delete  
D) Backups increase security risk, don't make any  

**Answer: C** - Store in different account, different region, with versioning + MFA delete

**Explanation:** If backups are in the same bucket or account, a compromised principal can delete both primary and backups. Separate account prevents this. Different region protects against regional disasters.

**Related Section:** README.md - "Fix 3 & 5"

---

### Question 25: Access Review Process
How often should you review S3 access permissions?

A) Once a year  
B) Monthly  
C) Only when incidents occur  
D) Quarterly minimum, monthly for production  

**Answer: D** - Quarterly minimum, monthly for production

**Explanation:** Regular reviews catch:
- Unused permissions (remove them)
- Former employees (revoke access)
- Credentials that may be compromised
- Policy configuration drift

Critical buckets (production) need more frequent reviews.

**Related Section:** IMPLEMENTATION_GUIDE.md - "Step 9: Monitoring & Maintenance"

---

### Question 26: Lambda Monitoring Function
In a Lambda monitoring function, what should trigger an alert?

A) All S3 access attempts  
B) Only successful uploads  
C) Only CRITICAL findings (public access, missing encryption, etc.)  
D) Alerts are not needed for S3  

**Answer: C** - Only CRITICAL findings

**Explanation:** Don't alert on every action (noise = ignored alerts). Alert only on security issues:
- Block Public Access disabled
- Public policies detected
- Encryption missing
- Versioning disabled

This maintains alert fatigue.

**Related Section:** s3_security_lambda.py - Alert logic

---

### Question 27: CloudTrail Data Events
Why enable CloudTrail data events for S3?

A) To know which buckets exist  
B) To record every GetObject, PutObject, DeleteObject call  
C) To automatically encrypt objects  
D) To improve upload speed  

**Answer: B** - To record every GetObject, PutObject, DeleteObject call

**Explanation:** CloudTrail data events create an audit trail of WHO accessed WHAT and WHEN. This is critical for:
- Compliance investigations
- Incident forensics
- Detecting unauthorized access
- Meeting GDPR/HIPAA requirements

**Related Section:** IMPLEMENTATION_GUIDE.md - "Step 7: Enable CloudTrail"

---

### Question 28: Least Privilege IAM Policy
Which of these follows Least Privilege best?

A) 
```
{
  "Effect": "Allow",
  "Action": "s3:*",
  "Resource": "*"
}
```

B) 
```
{
  "Effect": "Allow",
  "Action": ["s3:GetObject"],
  "Resource": "arn:aws:s3:::app-bucket/data/*"
}
```

C) 
```
{
  "Effect": "Allow",
  "Action": ["s3:*"],
  "Resource": ["arn:aws:s3:::*"]
}
```

D) All of the above are equal  

**Answer: B** - Limited action (GetObject only) on specific resource (specific bucket/prefix)

**Explanation:** Option B grants only:
- One action: GetObject (not delete, put, etc.)
- Specific resource: only app-bucket/data/* (not other buckets)

This is textbook Least Privilege.

**Related Section:** secure-iam-policy.json, iam-policy-scenarios.json

---

### Question 29: Incident Response
Your S3 bucket was public for 2 weeks. What is your FIRST step?

A) Calculate costs and fines  
B) Block public access immediately  
C) Start forensics  
D) Notify customers first  

**Answer: B** - Block public access immediately

**Explanation:** Incident response priorities:
1. **STOP the bleeding** (Block Public Access)
2. **CONTAIN** (Isolate bucket)
3. **INVESTIGATE** (Forensics)
4. **NOTIFY** (Customers, regulators, if required)

Stopping exposure before investigation prevents more damage.

**Related Section:** README.md - "Security Fixes"

---

### Question 30: Policy Validation
Before deploying a bucket policy, how should you test it?

A) Deploy directly to production  
B) Use AWS Policy Simulator to test specific actions  
C) Assuming it's correct without testing  
D) Test only after a breach occurs  

**Answer: B** - Use AWS Policy Simulator to test specific actions

**Explanation:** AWS Policy Simulator lets you test:
- Will this user have access?
- Will this action be allowed?
- Are there unintended denials?

This prevents misconfiguration before deployment.

**Related Section:** IMPLEMENTATION_GUIDE.md - "Troubleshooting" and boto3 policy simulation

---

## SECTION 4: COMPLIANCE & REGULATIONS (Questions 31-40)

### Question 31: GDPR Breach Notification Timeline
Under GDPR, how long do you have to notify customers after discovering a data breach?

A) 1 week  
B) 2 weeks  
C) 72 hours  
D) 30 days  

**Answer: C** - 72 hours

**Explanation:** GDPR mandates breach notification within 72 hours of discovery (unless you can demonstrate low risk). There's no grace period. This is why incident response must be fast.

**Related Section:** SECURITY_RISKS_AND_IMPACT.md - "GDPR"

---

### Question 32: HIPAA Encryption Requirement
Under HIPAA, is encryption required for every dataset?

A) No, only for especially sensitive data  
B) Yes, encryption is mandatory for all PHI (Protected Health Information)  
C) Encryption is optional  
D) HIPAA doesn't address encryption  

**Answer: B** - Yes, encryption is mandatory for all PHI

**Explanation:** HIPAA requires encryption for Protected Health Information (PHI) in transit and at rest. Exceptions are rare. An unencrypted PHI S3 bucket = automatic HIPAA violation.

**Related Section:** SECURITY_RISKS_AND_IMPACT.md - "HIPAA"

---

### Question 33: PCI-DSS Scope
Does PCI-DSS apply to all S3 buckets or only those storing card data?

A) All buckets, regardless of content  
B) Only buckets with card data  
C) PCI-DSS doesn't apply to cloud storage  
D) Only development buckets  

**Answer: B** - Only buckets with card data

**Explanation:** PCI-DSS (Payment Card Industry Data Security Standard) applies specifically to systems handling credit card data. If you don't store card data in S3, PCI-DSS doesn't directly apply, but compliance best practices still make sense.

**Related Section:** SECURITY_RISKS_AND_IMPACT.md - "PCI-DSS"

---

### Question 34: CCPA Right to Know
Under CCPA (California Consumer Privacy Act), what must companies do if a data breach occurs?

A) Nothing, privacy laws don't require notification  
B) Notify within 72 hours like GDPR  
C) Consumers have the right to know what data was accessed  
D) Only notify if data was "misused"  

**Answer: C** - Consumers have the right to know what data was accessed

**Explanation:** CCPA gives consumers the right to:
- Know what personal data is collected
- Access their data
- Delete their data
- Opt-out of data sales

Breaches require notification and disclosure of what was accessed.

**Related Section:** SECURITY_RISKS_AND_IMPACT.md - "CCPA"

---

### Question 35: SOC 2 Requirement
Does SOC 2 require S3 access logging?

A) No, SOC 2 doesn't cover cloud storage  
B) Recommended but optional  
C) Yes, SOC 2 Trust Service Criteria requires logging of data access  
D) Only for financial institutions  

**Answer: C** - Yes, SOC 2 Trust Service Criteria requires logging of data access

**Explanation:** SOC 2 Type II requires demonstrating:
- Access controls are effective
- Changes are logged and reviewed
- Systems are monitored

S3 access logs are evidence of these controls.

**Related Section:** README.md - "Fix 5: Enable Access Logging"

---

## SECTION 5: TOOLS & AUTOMATION (Questions 36-45)

### Question 36: Terraform Variable Override
In Terraform, what is the correct syntax to override the bucket_name variable?

A) `terraform apply bucket_name=my-bucket`  
B) `terraform apply -var="bucket_name=my-bucket"`  
C) `terraform apply --var bucket_name my-bucket`  
D) `terraform set bucket_name=my-bucket`  

**Answer: B** - `terraform apply -var="bucket_name=my-bucket"`

**Explanation:** Terraform uses `-var="key=value"` syntax. Quotes are important to handle special characters.

**Related Section:** main.tf - Usage instructions

---

### Question 37: AWS CLI Block Public Access
What is the correct AWS CLI command to enable all Block Public Access settings?

A) `aws s3api block-public-access --bucket my-bucket`  
B) `aws s3api put-public-access-block --bucket my-bucket --block-all`  
C)
```
aws s3api put-public-access-block \
  --bucket my-bucket \
  --public-access-block-configuration \ 
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```
D) `aws s3 make-private --bucket my-bucket`  

**Answer: C** - The correct command with all four settings

**Explanation:** The `put-public-access-block` command requires specific syntax with all four boolean settings clearly specified.

**Related Section:** IMPLEMENTATION_GUIDE.md - "Step 1"

---

### Question 38: Lambda Function Trigger
What is the best trigger for a security audit Lambda function?

A) Every S3 API call (too much noise)  
B) Only on object uploads (misses other changes)  
C) CloudWatch Events scheduled rule (e.g., daily or weekly)  
D) Manual execution only  

**Answer: C** - CloudWatch Events scheduled rule

**Explanation:** Scheduled audits (daily, weekly) provide consistent monitoring without overloading the function. This balances security with cost.

**Related Section:** s3_security_lambda.py - Deployment instructions

---

### Question 39: PowerShell Advantage Over Bash
When should you use the PowerShell S3 hardening script instead of Bash?

A) Never, Bash is always better  
B) Windows environments where PowerShell is native  
C) Only for Linux servers  
D) PowerShell is slower, avoid it  

**Answer: B** - Windows environments where PowerShell is native

**Explanation:** PowerShell is native to Windows, making it ideal for:
- Windows serveradministrators
- Organizations running mostly Windows
- CI/CD pipelines using Windows agents

Use the right tool for the environment.

**Related Section:** s3-security-hardening.ps1

---

### Question 40: IAM Policy Simulator Testing
Which of these is a valid use case for AWS IAM Policy Simulator?

A) Test if a principal has permission for a specific action  
B) Simulate user login  
C) Test network connectivity  
D) Check S3 storage usage  

**Answer: A** - Test if a principal has permission for a specific action

**Explanation:** The Policy Simulator shows:
- Will this action be allowed? (Yes/No/with conditions)
- Which policy allows/denies this?
- Are there conflicts?

This helps validate IAM policies before deploying.

**Related Section:** IMPLEMENTATION_GUIDE.md - "Verifying Security"

---

## SECTION 6: PRODUCTION SCENARIOS (Questions 41-50)

### Question 41: Multi-Account S3 Access
Your company has separate AWS accounts for dev, staging, and production. You need dev EC2 instances to access production S3 backups. What's the recommended approach?

A) Use hardcoded AWS credentials in EC2 (never do this)  
B) STS AssumeRole cross-account access with IAM roles  
C) Grant everyone S3 admin access for simplicity  
D) Don't allow cross-account access; it's always insecure  

**Answer: B** - STS AssumeRole cross-account access with IAM roles

**Explanation:** STS AssumeRole is the secure way:
1. Dev role gets permission to AssumeRole on prod role
2. Prod role trusts the dev account
3. No hardcoded credentials
4. Automatic temporary credentials with expiration
5. Full audit trail

**Related Section:** iam-policy-scenarios.json - "Scenario 3: Cross-Account Access"

---

### Question 42: Data Science Notebook Access
A data scientist needs read access to training datasets and write access to analysis output, but should NOT delete anything. What policy do you create?

A) Grant s3:FullAccess (simplest)  
B) Allow GetObject + ListBucket for training data; PutObject for output; Deny DeleteObject  
C) Use credentials and rotate them manually  
D) Extend data scientist local admin access  

**Answer: B** - Specific allow/deny structure

**Explanation:** This follows Least Privilege:
- GetObject: Read training data
- ListBucket: List files in training directory
- PutObject: Write analysis results
- Deny DeleteObject: Prevent accidental/malicious deletion

**Related Section:** iam-policy-scenarios.json - "Scenario 9: Data Scientist"

---

### Question 43: Ransomware Scenario Simulation
A ransomware attack compromises an EC2 instance with S3 access. Rankings by damage:

1. Instance can download bucket data but NOT modify policies
2. Instance can list and delete objects
3. Instance can modify bucket policies to make it public
4. Instance can delete bucket versions with MFA Delete enabled

Which ranking is correct (highest damage first)?

A) 3 > 1 > 2 > 4  
B) 4 > 3 > 2 > 1  
C) 3 > 2 > 4 > 1  
D) 2 > 4 > 3 > 1  

**Answer: C** - 3 > 2 > 4 > 1

**Explanation:**
1. **Policy modification** (3): Can make bucket public, sell data
2. **Delete objects** (2): Can delete data, demand ransom
3. **MFA Delete blocks deletion** (4): Cannot delete, but can still do other damage
4. **Download only** (1): Limited impact, can steal data but not ransom it

**Related Section:** README.md - "Ransomware" section

---

### Question 44: CloudTrail Cost Optimization
You're logging all S3 data events to CloudTrail. The logs are huge (100GB/month). How do you optimize?

A) Disable CloudTrail entirely (save costs)  
B) Use lifecycle rules to transition old logs to Glacier  
C) Only log critical buckets  
D) Log only in production, not dev  

**Answer: C** - Only log critical buckets

**Explanation:** You don't need to log development/non-critical buckets. CloudTrail allows:
- Filtering by resource (only log prod-* buckets)
- Filtering by action (only log DeleteObject)
- Filtering by role

This reduces costs 5-10x while maintaining key audits.

**Related Section:** main.tf - CloudTrail configuration

---

### Question 45: Timeline: From Misconfigured to Breach
Estimate the timeline for a public S3 bucket to be discovered and exploited:

A) Hours  
B) Days  
C) Weeks  
D) Never (it's not discoverable)  

**Answer: A) Hours to days (sometimes detected within 24 hours by automated scanners)

**Explanation:** Automated S3 scanners run 24/7. A public bucket with an obvious name (company-backup, company-prod) is typically:
- Discovered: Hours to 48 hours
- Exploited: Immediately
- Noticed by owner: 6-18 months later

This is why public buckets shouldn't exist.

**Related Section:** README.md - "How Attackers Access Data"

---

## SECTION 7: ADVANCED TOPICS (Questions 46-50)

### Question 46: Bucket Object Lock
What is S3 Object Lock used for?

A) Preventing public access  
B) Implementing WORM (Write Once, Read Many) storage  
C) Encrypting objects  
D) Improving upload performance  

**Answer: B** - Implementing WORM (Write Once, Read Many) storage

**Explanation:** Object Lock prevents object deletion or modification for a specified retention period. Uses:
- Compliance: Cannot be bypassed even by admin
- Governance: Admin can override with special permission
- Legal holds: Indefinite retention for litigation

This is for records management, not general security.

**Related Section:** main.tf - Object Lock configuration (optional)

---

### Question 47: VPC Endpoint for S3
What is the benefit of using a VPC Endpoint for S3?

A) Faster uploads  
B) Data doesn't leave your VPC; calls don't traverse the internet  
C) Cheaper S3 storage  
D) Automatic encryption  

**Answer: B** - Data doesn't leave your VPC; calls don't traverse the internet

**Explanation:** A VPC Endpoint for S3:
- Routes traffic through AWS internal network
- Doesn't go over the internet (safer)
- Reduces data transfer costs
- Can apply endpoint policies for additional control

**Related Section:** Could be implemented in Terraform for production deployments

---

### Question 48: S3 Bucket Policies vs. Access Points
When should you use S3 Access Points instead of bucket policies?

A) Never, bucket policies are always better  
B) For multi-account/multi-tenant access patterns  
C) Only for small buckets  
D) Access Points don't exist  

**Answer: B** - For multi-account/multi-tenant access patterns

**Explanation:** Access Points simplify:
- Multi-tenancy (each tenant gets an access point)
- Cross-region access (can replicate across regions)
- Policy management (multiple policies instead of one complex policy)

Think of them as "simplified bucket doors."

**Related Section:** Advanced Terraform configuration (not included in basic lab)

---

### Question 49: S3 Replication vs. Versioning
A company needs backup/disaster recovery. Should they use S3 Replication or just Versioning?

A) Versioning only (simpler)  
B) Replication only (better for DR)  
C) Both: Versioning for recovery from mistakes, Replication for disaster recovery  
D) Neither, use backup services  

**Answer: C** - Both: Versioning for recovery from mistakes, Replication for disaster recovery

**Explanation:**
- **Versioning**: Protects against accidental deletion/modification (same bucket)
- **Replication**: Protects against regional disaster (different region/account)
- **Together**: Defense in depth for both types of failures

**Related Section:** README.md - "Fix 3 & 5"

---

### Question 50: Zero Trust Architecture
How does Zero Trust apply to S3?

A) Trust no one, disable S3 entirely  
B) Assume breach: require auth for every access, log everything, use least privilege  
C) Trust AWS to keep S3 safe  
D) Trust only within your company  

**Answer: B** - Assume breach: require auth for every access, log everything, use least privilege

**Explanation:** Zero Trust for S3:
1. **Never trust by default**: Deny all, then allow specific
2. **Always verify**: IAM + encryption + conditions
3. **Least privilege**: Minimal permissions
4. **Assume breach**: Design as if attacker has one credential
5. **Log everything**: CloudTrail + access logs

This is security best practice.

**Related Section:** Entire documentation emphasizes this approach

---

## ANSWER KEY SUMMARY

**Beginner Level (Q1-10):** Basic concepts  
**Intermediate Level (Q11-30):** Attacks, defenses, tools  
**Advanced Level (Q31-50):** Compliance, production, advanced architecture  

---

## SCORING GUIDE

- **40-50 correct**: AWS S3 Security Expert
- **30-40 correct**: Proficient (can design secure S3 architecture)
- **20-30 correct**: Intermediate (can implement basic security)
- **10-20 correct**: Beginner (time to study README)
- **Below 10**: Review README thoroughly before deployment

---

## NEXT STEPS

1. Review sections with low scores
2. Deep dive into referenced documentation
3. Implement in lab environment
4. Retake assessment in 1 week
5. Deploy to production

---

**Assessment Version**: 1.0  
**Last Updated**: April 2026
