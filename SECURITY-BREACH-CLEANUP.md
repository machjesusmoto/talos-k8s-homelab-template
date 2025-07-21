# URGENT: Security Breach Cleanup Instructions

## Critical Security Issue Detected

The `secrets.yaml` file containing production Talos cluster secrets was committed to Git history and is still accessible in past commits. This is a critical security breach.

## Immediate Actions Required

### 1. Rotate All Compromised Secrets

**CRITICAL**: Since this repository is public on GitHub, assume all secrets are compromised.

1. **Regenerate Talos Secrets**:
   ```bash
   # Generate new secrets for the cluster
   talosctl gen secrets -o secrets-new.yaml
   
   # You will need to rebuild the cluster with new secrets
   ```

2. **Rotate Any Other Exposed Credentials**:
   - VPN credentials (if any were exposed)
   - API tokens
   - Any passwords in the repository

### 2. Clean Git History

You have two options:

#### Option A: Complete History Rewrite (Recommended)
```bash
# Install BFG Repo-Cleaner
wget https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar

# Remove secrets.yaml from entire history
java -jar bfg-1.14.0.jar --delete-files secrets.yaml

# Clean up the repository
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push to GitHub (this will rewrite history)
git push --force origin main
```

#### Option B: Start Fresh Repository
1. Create a new repository
2. Copy only the current files (no history)
3. Archive or delete the old repository

### 3. Verify Cleanup

After cleaning:
```bash
# Verify secrets.yaml is gone from history
git log --all --full-history -- secrets.yaml

# Check for any other sensitive files
git log --all --full-history --name-only | grep -E "secret|token|password"
```

### 4. Update GitHub Repository

1. If the repository was public, it may have been cloned/forked
2. Consider making the repository private temporarily
3. Add a security notice to the README about the rotation

### 5. Implement Prevention Measures

1. **Pre-commit Hook** to prevent secrets:
   ```bash
   # .git/hooks/pre-commit
   #!/bin/bash
   if git diff --cached --name-only | grep -E "secrets?.yaml|.*secret.*\.yaml"; then
     echo "ERROR: Attempting to commit secrets file!"
     exit 1
   fi
   ```

2. **Use git-secrets or similar tools**:
   ```bash
   brew install git-secrets
   git secrets --install
   git secrets --register-aws
   ```

## Affected Secrets

Based on the exposed `secrets.yaml`:
- Cluster ID: `ucZYlK5eguAmjgqwSbCX8K_PttOwm8ujjQjVxlNr57Q=`
- Cluster Secret: `FTdRH2YAUhx1/FtneI+7GTxNsTgibXS2p8nlkHSNByM=`
- Bootstrap Token: `6pn3cc.wnw8if1jpezpie7d`
- Encryption Secret: `n3d0YGjCaHbMLI4narrq2HNdO5n8t31+WfuAwJnIpFE=`
- Trust Token: `qsrznh.0du4iu90872y52bg`

**ALL OF THESE MUST BE CONSIDERED COMPROMISED**

## Timeline

- Secrets were committed before the repository split
- The commit `e9af679` removed secrets.yaml but it remains in parent commits
- Anyone with repository access can retrieve these secrets

## Recommendations

1. **Immediate**: Rotate all secrets
2. **Today**: Clean Git history or create new repository
3. **Ongoing**: Implement secret scanning in CI/CD
4. **Future**: Use external secret management (Sealed Secrets, SOPS, Vault)

## Contact

If you need assistance with cleanup or have questions about the impact, consider reaching out to security professionals or the Talos community for guidance.