# Repository Settings

This document describes the required GitHub repository settings for the automated update workflow to function correctly.

## Required Settings

### GitHub Actions Permissions

1. Go to **Settings** > **Actions** > **General**
2. Under "Workflow permissions", select:
   - **Read and write permissions**
   - Check **Allow GitHub Actions to create and approve pull requests**

### Branch Protection (Optional but Recommended)

If you have branch protection on `main`:
1. Go to **Settings** > **Branches** > **Branch protection rules**
2. For the `main` branch rule, ensure:
   - "Require status checks to pass before merging" is enabled
   - Add `test-build` as a required status check

### Auto-merge

For auto-merge to work:
1. Go to **Settings** > **General**
2. Under "Pull Requests", check **Allow auto-merge**

## Secrets

### Required Secrets

- `CACHIX_AUTH_TOKEN`: Auth token for the `gemini-cli-nix-cache` Cachix cache (optional but recommended for binary caching)

### Optional Secrets

- `GITHUB_TOKEN`: Automatically provided by GitHub Actions

## Verification

You can verify your settings using the GitHub CLI:

```bash
# Check repository settings
gh repo view --json defaultBranchRef,mergeCommitAllowed,squashMergeAllowed

# Check workflow permissions (requires admin access)
gh api repos/{owner}/{repo}/actions/permissions
```

## Troubleshooting

### PRs not being created
- Verify workflow permissions allow write access
- Check if the `GITHUB_TOKEN` has necessary permissions

### Auto-merge not working
- Ensure auto-merge is enabled in repository settings
- Check if required status checks are passing
- Verify the PR author has permission to enable auto-merge

### Build failures
- Check if `CACHIX_AUTH_TOKEN` secret is set (optional but recommended)
- Verify the nix build works locally first
