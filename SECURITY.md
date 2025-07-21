# Security Guidelines for k8s-homelab-migration

## Secret Management

### ⚠️ CRITICAL: Never Commit Secrets

The following files contain sensitive information and must NEVER be committed to version control:

- `secrets.yaml` - Talos cluster secrets (bootstrap tokens, certificates, encryption keys)
- `*-secret.yaml` - Any file ending with `-secret.yaml` (unless it's a `-template.yaml`)
- `*.key`, `*.pem`, `*.crt` - Private keys and certificates
- Any file containing API tokens, passwords, or credentials

### Using Secret Templates

All secrets should have corresponding template files with `-template.yaml` suffix:

1. Template files contain placeholders like:
   - `YOUR_USERNAME_HERE`
   - `YOUR_PASSWORD_HERE`
   - `CONFIGURE: <description>`

2. Copy the template and create your actual secret file:
   ```bash
   cp vpn-secret-template.yaml vpn-secret.yaml
   # Edit vpn-secret.yaml with your actual values
   ```

3. The actual secret files are gitignored and won't be committed

### Credential Rotation

If credentials are accidentally exposed:

1. **Immediately revoke/rotate the exposed credentials:**
   - Cloudflare API tokens: Dashboard → My Profile → API Tokens
   - VPN credentials: Provider's account dashboard
   - Cluster secrets: Regenerate using `talosctl gen secrets`

2. **Remove from Git history:**
   ```bash
   # Use BFG Repo-Cleaner or git filter-branch
   bfg --delete-files secrets.yaml
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   ```

3. **Force push to remote:**
   ```bash
   git push --force-with-lease origin main
   ```

## Security Best Practices

### 1. Pre-commit Checks

Consider using tools to prevent secret commits:
- [gitleaks](https://github.com/gitleaks/gitleaks)
- [detect-secrets](https://github.com/Yelp/detect-secrets)

### 2. External Secret Management

For production use, consider:
- **Sealed Secrets**: Encrypt secrets that can be stored in Git
- **SOPS**: Encrypt files with cloud KMS
- **HashiCorp Vault**: Full secret management solution
- **Kubernetes External Secrets**: Sync secrets from external stores

### 3. Default Passwords

Never use default passwords in production:
- Change all default passwords immediately after deployment
- Use strong, unique passwords for each service
- Consider using a password manager for generation

### 4. Network Security

- Use NetworkPolicies to restrict pod-to-pod communication
- Implement proper ingress rules with authentication
- Use TLS for all external-facing services
- Restrict LoadBalancer services to necessary IPs only

### 5. RBAC and Access Control

- Follow principle of least privilege
- Create service-specific ServiceAccounts
- Limit namespace access for applications
- Regular audit of permissions

## Security Checklist

Before committing:
- [ ] Run `git status` to check for sensitive files
- [ ] Verify all secrets use template files
- [ ] Ensure no hardcoded credentials in code
- [ ] Check that API tokens are parameterized
- [ ] Confirm .gitignore includes all secret patterns

## Reporting Security Issues

If you discover a security vulnerability:
1. Do NOT create a public issue
2. Email security concerns to the repository owner
3. Include steps to reproduce if possible
4. Allow time for patching before disclosure

## Resources

- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [OWASP Kubernetes Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Kubernetes_Security_Cheat_Sheet.html)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)