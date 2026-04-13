# Contributing to AWS Cloud Security Lab

Thank you for your interest in contributing! This guide will help you get started.

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on ideas, not individuals
- Help others learn and grow

## How to Contribute

### 1. Reporting Issues

Found a bug or have a suggestion? Please create an issue with:
- Clear title describing the problem
- Detailed description of the issue
- Steps to reproduce (for bugs)
- Expected vs actual behavior
- Your environment (OS, Python version, AWS CLI version, etc.)

### 2. Suggesting Improvements

Have an idea? Open an issue with:
- Clear title
- Detailed description of the feature
- Why this would be useful
- Potential implementation approach

### 3. Submitting Changes

**For Small Changes** (typos, clarifications):
1. Fork the repository
2. Create a branch: `git checkout -b fix/description`
3. Make your changes
4. Commit: `git commit -m "Fix: Clear description"`
5. Push: `git push origin fix/description`
6. Open a Pull Request

**For Large Changes** (new features, major rewrites):
1. Open an issue first to discuss the approach
2. Wait for feedback from maintainers
3. Once approved, follow the small changes process above

### 4. Contribution Areas

**We're looking for help with**:
- Additional case studies and breach examples
- Industry-specific security scenarios
- Localization/translation of content
- Video production using provided scripts
- Additional automation tools (Ansible, CloudFormation, etc.)
- Assessment question expansion
- Diagram and visualization improvements
- Spell-checking and grammar improvements
- Technical accuracy reviews

**Areas we DON'T need help with right now**:
- Changing core security best practices (these are battle-tested)
- Removing or significantly reducing content
- Adding unverified breach information

## Development Setup

### Prerequisites
```bash
# Git
git --version  # Should be 2.0+

# Python (for Lambda development)
python3 --version  # Should be 3.8+

# AWS CLI
aws --version  # Should be 2.x

# Terraform (for IaC changes)
terraform version  # Should be 1.0+
```

### Local Setup
```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/aws-cloud-security-lab.git
cd aws-cloud-security-lab

# Create a branch
git checkout -b feature/your-feature

# Make changes
# ... edit files ...

# Test your changes
bash scripts/validate.sh  # If it exists
```

## Content Guidelines

### Documentation
- Use clear, simple language
- Include real examples
- Link to related sections
- Format code blocks consistently
- Include line numbers for long files

### Code/Scripts
- Include comments explaining complex logic
- Add error handling
- Test on multiple platforms (Bash on Linux/Mac, PowerShell on Windows)
- Follow security best practices
- Include usage examples

### Policies
- Match the existing JSON style
- Include explanation comments
- Specify the use case
- Test with AWS Policy Simulator

### Assessment Questions
- Include detailed answer explanations
- Link to related documentation
- Provide difficulty level
- Include correct answer first

## Commit Messages

Use clear, descriptive commit messages:

```
# Good
git commit -m "Add: New scenario for cross-account S3 access"
git commit -m "Fix: Lambda function error handling for missing buckets"
git commit -m "Docs: Clarify Least Privilege explanation with examples"

# Avoid
git commit -m "Update"
git commit -m "Fix stuff"
git commit -m "More changes"
```

Format:
- Start with action: `Add:`, `Fix:`, `Docs:`, `Refactor:`, `Test:`
- Be specific about what changed
- Keep under 72 characters

## Pull Request Process

1. **Fill out the PR template** (if provided)
2. **Link related issues**: "Closes #123"
3. **Describe your changes clearly**
4. **Explain why this change is needed**
5. **Provide testing evidence** (screenshots, test results)
6. **Request review** from 1-2 maintainers

### PR Checklist
- [ ] My code follows the project's style guidelines
- [ ] I have updated relevant documentation
- [ ] I have tested my changes
- [ ] I have not added unverified information
- [ ] I have included comments for complex logic
- [ ] My commit messages are clear and descriptive

## Testing Your Changes

### For Documentation Changes
```bash
# Check formatting
cat YOUR_FILE.md | less

# Verify links (if you have a markdown linter)
markdownlint YOUR_FILE.md
```

### For Script Changes
```bash
# Test the script
bash s3-security-hardening.sh my-test-bucket  # Bash
pwsh s3-security-hardening.ps1 -BucketName my-test  # PowerShell
```

### For Terraform Changes
```bash
# Validate syntax
terraform validate

# Format check
terraform fmt -check

# Plan (don't apply!)
terraform plan -out=tfplan
```

### For Python Changes
```bash
# Check syntax
python3 -m py_compile s3_security_lambda.py

# Run with test event (if available)
python3 s3_security_lambda.py
```

## Documentation Standards

### For new files
- Start with a clear title
- Add a 2-3 sentence purpose statement
- Include a table of contents for long documents
- Use consistent formatting
- Include examples where helpful
- Add related section references

### For code comments
```python
# Good - explains WHY, not just WHAT
def check_block_public_access(bucket_name):
    """
    Verify Block Public Access is enabled.
    This is critical because even properly configured bucket policies
    can be accidentally modified. Block Public Access acts as a safety
    net to prevent public exposure.
    """
    
# Avoid - just restates the code
def check_block_public_access(bucket_name):
    """Check if block public access is enabled"""
```

## Review Process

1. **Automated checks** run (linting, formatting, syntax)
2. **Maintainer review** of your changes
3. **Feedback and discussion** if needed
4. **Approval** once everything looks good
5. **Merge** to main branch

## Community Support

- **Questions?** Open an issue with the `question` label
- **Having trouble?** Check existing issues for similar problems
- **Want to discuss?** Use the Discussions feature (if enabled)

## Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md (when created)
- GitHub contributors graph
- Release notes (for significant contributions)

## License

By contributing, you agree that your contributions will be licensed under the same MIT License as the project.

---

**Questions?** Open an issue or reach out to the maintainers.

Thank you for making this project better! 🚀
