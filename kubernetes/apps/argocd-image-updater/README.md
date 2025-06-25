# ArgoCD Image Updater

Automatically update container images in ArgoCD applications using GitOps principles.

## Features

- **GitOps Workflow**: Updates Git repositories instead of directly modifying running containers
- **Multiple Registries**: Support for Docker Hub, GitHub Container Registry, Quay, and custom registries
- **Selective Updates**: Configure which applications and images to update automatically
- **Version Constraints**: Support for semantic versioning constraints and update policies
- **Integration**: Works seamlessly with existing ArgoCD applications

## How It Works

1. **Monitors**: Scans container registries for new image versions
2. **Analyzes**: Checks configured applications for outdated images
3. **Updates**: Creates Git commits with updated image tags
4. **Triggers**: ArgoCD detects Git changes and syncs applications

## Configuration

### Enable for Applications

Add annotations to ArgoCD applications to enable image updating:

```yaml
# In your ArgoCD Application spec
metadata:
  annotations:
    # Enable image updater for this application
    argocd-image-updater.argoproj.io/image-list: "gluetun=qmcgaw/gluetun:^v3.0.0"
    
    # Update strategy
    argocd-image-updater.argoproj.io/update-strategy: "latest"
    
    # Write back method
    argocd-image-updater.argoproj.io/write-back-method: "git"
    
    # Git commit message template
    argocd-image-updater.argoproj.io/git-commit-message: "chore: update {{.AppName}} image to {{.NewTag}}"
```

### Update Strategies

- **`latest`**: Always use the latest available tag
- **`semver`**: Use semantic versioning constraints (e.g., `^v1.0.0`)
- **`digest`**: Update to latest digest of the same tag

### Version Constraints

```yaml
# Semantic versioning examples
argocd-image-updater.argoproj.io/image-list: |
  gluetun=qmcgaw/gluetun:^v3.0.0      # Allow minor/patch updates
  portainer=portainer/portainer-ce:~2.19.0  # Allow patch updates only
  traefik=traefik:^v3.0.0             # Allow minor/patch updates
```

## Example Configurations

### 1. Enable for Gluetun
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: gluetun
  annotations:
    argocd-image-updater.argoproj.io/image-list: "gluetun=qmcgaw/gluetun"
    argocd-image-updater.argoproj.io/update-strategy: "semver:^v3.0.0"
    argocd-image-updater.argoproj.io/write-back-method: "git"
```

### 2. Enable for Multiple Images
```yaml
metadata:
  annotations:
    argocd-image-updater.argoproj.io/image-list: |
      app=myapp/myapp:^v1.0.0
      sidecar=myapp/sidecar:latest
    argocd-image-updater.argoproj.io/update-strategy: "latest"
```

### 3. Custom Registry
```yaml
metadata:
  annotations:
    argocd-image-updater.argoproj.io/image-list: "app=ghcr.io/owner/app:^v1.0.0"
    argocd-image-updater.argoproj.io/app.platforms: "linux/amd64"
```

## Git Integration

### Requirements
- **Read Access**: Image updater needs to read ArgoCD applications
- **Write Access**: Must be able to push commits to your Git repository

### Authentication
For private repositories, create SSH key or access token:

```bash
# Create SSH key secret (if using SSH)
kubectl create secret generic argocd-image-updater-ssh-config \
  -n argocd-image-updater \
  --from-file=ssh_config=/path/to/ssh_config \
  --from-file=id_rsa=/path/to/private_key

# Or create Git token secret (if using HTTPS)
kubectl create secret generic argocd-image-updater-git-token \
  -n argocd-image-updater \
  --from-literal=token=your-git-token
```

## Monitoring

### Logs
```bash
# View image updater logs
kubectl logs -n argocd-image-updater deployment/argocd-image-updater -f

# Check for update activities
kubectl logs -n argocd-image-updater deployment/argocd-image-updater | grep "Processing application"
```

### Metrics
The image updater exposes Prometheus metrics on port 8080:
- `argocd_image_updater_applications_watched`
- `argocd_image_updater_images_updated_total`
- `argocd_image_updater_registry_requests_total`

### Events
```bash
# Check Kubernetes events for update activities
kubectl get events -n argocd-image-updater --sort-by='.lastTimestamp'
```

## Security Considerations

- **Registry Authentication**: Configure credentials for private registries
- **Git Authentication**: Use minimal permissions for Git access
- **Image Verification**: Consider implementing image signing verification
- **Network Policies**: Restrict network access to required registries only

## Common Patterns

### Production Safety
```yaml
# Only allow patch updates in production
argocd-image-updater.argoproj.io/image-list: "app=myapp:~1.2.0"

# Exclude from automatic updates
argocd-image-updater.argoproj.io/ignore-tags: "latest,dev,beta"
```

### Development Environments
```yaml
# Always use latest for development
argocd-image-updater.argoproj.io/image-list: "app=myapp:latest"
argocd-image-updater.argoproj.io/update-strategy: "latest"
```

### Staged Updates
```yaml
# Update staging first, then production manually
argocd-image-updater.argoproj.io/image-list: "app=myapp"
argocd-image-updater.argoproj.io/platforms: "linux/amd64"
```

## Troubleshooting

### Updates Not Happening
1. Check image updater logs for errors
2. Verify application annotations are correct
3. Ensure Git authentication is working
4. Check registry connectivity

### Git Authentication Issues
```bash
# Test Git access
kubectl exec -n argocd-image-updater deployment/argocd-image-updater -- \
  git ls-remote https://github.com/your-repo.git
```

### Registry Access Issues
```bash
# Test registry connectivity
kubectl exec -n argocd-image-updater deployment/argocd-image-updater -- \
  curl -I https://registry-1.docker.io/v2/
```

## Best Practices

1. **Start Small**: Enable for non-critical applications first
2. **Use Constraints**: Always specify version constraints for production
3. **Monitor Changes**: Review automated commits before they reach production
4. **Test Updates**: Ensure your applications handle image updates gracefully
5. **Backup Strategy**: Have rollback procedures for failed updates
6. **Security Scanning**: Integrate with security scanners for new images