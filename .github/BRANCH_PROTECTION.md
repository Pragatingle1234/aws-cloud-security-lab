# GitHub Branch Protection Configuration

This document describes the recommended branch protection settings for the AWS Cloud Security Lab repository.

## Recommended Settings for `main` Branch

### 1. **Require Pull Request Reviews**
- ✅ Require pull request reviews before merging
- ✅ Dismiss stale pull request approvals when new commits are pushed
- ✅ Require review from code owners

### 2. **Require Status Checks to Pass**
- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging
- ✅ Require passing status checks:
  - `Validate Project Files`
  - `Publish Documentation`
  - `Security Scan`

### 3. **Require Code Reviews and Approvals**
- ✅ Require at least 1 approval
- ✅ Require review from code owners
- ✅ Dismiss stale reviews

### 4. **Require Signed Commits**
- ✅ Require signed commits (recommended for security)

### 5. **Include Administrators**
- ✅ Enforce all the above rules on administrators

## How to Apply These Settings

1. Go to your repository on GitHub
2. Settings → Branches
3. Under "Branch protection rules", click "Add rule"
4. Branch name pattern: `main`
5. Configure the following options:
   - ✅ Require pull request reviews before merging
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
   - ✅ Require code owner reviews
   - ✅ Require signed commits
   - ✅ Include administrators

## CI/CD Workflow Protection

### GitHub Actions Status Checks
The following status checks are automatically run on every push and pull request:

1. **Validate Project Files** (`validate.yml`)
   - Checks all markdown files exist
   - Validates JSON syntax
   - Checks shell script syntax
   - Verifies all key files present

2. **Security Scan** (`security.yml`)
   - Secret detection
   - Vulnerability scanning
   - Hardcoded credential detection
   - JSON policy validation

3. **Publish Documentation** (`publish.yml`)
   - Builds documentation site
   - Publishes to GitHub Pages
   - Creates landing page

## Development Branch Strategy

```
main (production)
├── develop (staging)
├── docs (documentation)
├── feature/* (new features)
└── bugfix/* (bug fixes)
```

### Branch Naming Convention
- `feature/` - New features: `feature/add-lambda-monitoring`
- `bugfix/` - Bug fixes: `bugfix/fix-json-formatting`
- `docs/` - Documentation: `docs/add-deployment-guide`
- `refactor/` - Code improvements: `refactor/optimize-scripts`
- `test/` - Test additions: `test/add-assessment-questions`

## Pull Request Workflow

1. Create feature branch from `main` or `develop`
2. Make changes and commit
3. Push to GitHub
4. Create Pull Request
5. GitHub Actions automatically run status checks
6. Once all checks pass, request code owner review
7. After approval, merge to target branch

## Commit Message Format

```
type: subject

Body (optional)
- More detailed explanation
- List of changes if applicable

Footer (optional)
Closes #123
```

### Commit Types
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation change
- `style:` - Code style change
- `refactor:` - Code refactoring
- `test:` - Test addition or modification
- `chore:` - Build process, dependencies, etc.

## Examples

```
feat: Add AWS CLI multi-account support

- Implements role assumption logic
- Adds AWS credentials validation
- Updates IMPLEMENTATION_GUIDE.md

Closes #42
```

```
docs: Update security risks section with new breach case study

- Added 2023 financial sector breach analysis
- Updated penalty calculations
- Added new compliance section
```

## Protection Policy Summary

| Rule | Status | Reason |
|------|--------|--------|
| Require PR reviews | ✅ | Ensures code quality |
| Require status checks | ✅ | Validates documentation & security |
| Require branch updates | ✅ | Prevents merge conflicts |
| Require code owner review | ✅ | Ensures expert review |
| Require signed commits | ✅ | Improves security |
| Enforce on admins | ✅ | Consistent policy application |

## Troubleshooting

### "Checks expected to pass but are missing"
- Solution: Wait for all GitHub Actions to complete (usually 2-5 minutes)

### "Branch is out of date"
- Solution: Click "Update branch" button on the PR page

### "Changes requested"
- Solution: Address feedback in comments and push new commits

### "Commit not signed"
- Solution: Configure GPG signing locally: `git config user.signingkey YOUR_KEY_ID`

## Additional Resources

- [GitHub Docs: Branch Protection](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub Docs: Code Owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
- [GitHub Docs: Signing Commits](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits)
