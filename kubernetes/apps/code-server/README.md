# Code-Server Development Environment

VS Code in the browser - access a full development environment from anywhere with HTTPS and authentication.

## Features

- **Full VS Code Experience**: Complete VS Code interface with extensions support
- **Remote Development**: Access from any device with a web browser
- **Persistent Storage**: Projects and settings preserved across restarts
- **Docker Integration**: Docker socket mounted for container development
- **Git Integration**: Full Git support with SSH key configuration
- **Secure Access**: Password authentication with HTTPS via Let's Encrypt
- **Customizable**: Pre-configured with development-friendly settings

## Access

- **URL**: https://code.k8s.dttesting.com
- **Authentication**: Password-based (configured via secret)
- **Protocol**: HTTPS with automatic SSL certificate

## Setup Instructions

### 1. Configure Authentication

Copy the secret template and set your password:

```bash
cp secret-template.yaml secret.yaml
```

Edit `secret.yaml` and set a strong password:

```yaml
stringData:
  PASSWORD: "your-strong-password-here"
```

Apply the secret:

```bash
kubectl apply -f secret.yaml
```

### 2. Optional: SSH Key Configuration

For Git operations, add your SSH keys to the secret:

```yaml
stringData:
  PASSWORD: "your-password"
  ssh-privatekey: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    your-private-key-here
    -----END OPENSSH PRIVATE KEY-----
  ssh-publickey: "ssh-rsa your-public-key-here"
```

### 3. Deploy via ArgoCD

The application will be automatically deployed once committed to Git.

## Storage Layout

- **Data Volume**: `/home/coder/.local/share/code-server` (10GB)
  - VS Code settings, extensions, workspace data
- **Projects Volume**: `/home/coder/projects` (20GB)
  - Your development projects and repositories

## Pre-installed Features

### Development Tools
- **Git**: Full Git client with SSH support
- **Docker**: Access to Docker daemon for container development
- **Node.js**: JavaScript/TypeScript development
- **Python**: Python development environment
- **Terminal**: Integrated terminal with full shell access

### VS Code Configuration
- **Theme**: Default Dark+ theme
- **Fonts**: Fira Code with ligatures enabled
- **Settings**: Auto-save, Git integration, optimized for development
- **Extensions**: Ready for additional extension installation

### Security Settings
- **Telemetry**: Disabled for privacy
- **Updates**: Disabled (managed via container updates)
- **File Downloads**: Enabled for project export

## Docker Development

Code-server has access to the Docker socket for container development:

```bash
# Build and run containers
docker build -t myapp .
docker run -p 3000:3000 myapp

# Compose projects
docker-compose up -d

# Access docker commands
docker ps
docker logs container-name
```

## Git Configuration

Set up Git credentials in the terminal:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"

# For SSH keys (if configured in secret)
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```

## Extension Management

Install extensions through the VS Code interface or command line:

```bash
# Install popular extensions
code-server --install-extension ms-python.python
code-server --install-extension ms-vscode.vscode-typescript-next
code-server --install-extension ms-vscode.docker
code-server --install-extension gitpod.gitpod-theme
```

## Performance Optimization

### Resource Allocation
- **CPU**: 200m request, 2000m limit
- **Memory**: 512Mi request, 2Gi limit
- **Storage**: NFS-backed persistent volumes

### Browser Performance
- Use modern browsers (Chrome, Firefox, Safari, Edge)
- Enable hardware acceleration
- Close unused tabs and extensions

## Security Features

### Authentication
- Password-based authentication
- Session management
- Secure cookie handling

### Network Security
- HTTPS-only access via Traefik
- Let's Encrypt SSL certificates
- Security headers configured

### Container Security
- Non-root user execution
- Read-only root filesystem where possible
- Minimal capabilities

## Backup and Recovery

### Manual Backup
```bash
# Backup projects
kubectl exec -n code-server deployment/code-server -- tar -czf - /home/coder/projects > projects-backup.tar.gz

# Backup settings
kubectl exec -n code-server deployment/code-server -- tar -czf - /home/coder/.local/share/code-server > settings-backup.tar.gz
```

### Restore from Backup
```bash
# Restore projects
kubectl exec -n code-server deployment/code-server -- tar -xzf - -C / < projects-backup.tar.gz

# Restore settings
kubectl exec -n code-server deployment/code-server -- tar -xzf - -C / < settings-backup.tar.gz
```

## Troubleshooting

### Connection Issues
```bash
# Check pod status
kubectl get pods -n code-server

# Check logs
kubectl logs -n code-server deployment/code-server

# Check service
kubectl describe service code-server -n code-server
```

### Storage Issues
```bash
# Check PVC status
kubectl get pvc -n code-server

# Check storage usage
kubectl exec -n code-server deployment/code-server -- df -h
```

### Performance Issues
- Check resource usage in VS Code
- Disable unnecessary extensions
- Clear browser cache
- Restart the code-server pod

## Common Use Cases

### Web Development
- Node.js/React/Vue.js projects
- HTML/CSS/JavaScript development
- Real-time preview with port forwarding

### Container Development
- Dockerfile creation and testing
- Docker Compose orchestration
- Kubernetes manifest development

### Remote Collaboration
- Shared development environment
- Code review and pair programming
- Team project access

### Learning and Experimentation
- Safe environment for testing code
- Multiple language support
- Isolated development workspace

## Advanced Configuration

### Custom Extensions
Add to deployment or install via UI:
```bash
# Language servers
ms-python.python
ms-vscode.cpptools
golang.go

# Productivity
gitlens.gitlens
ms-vsliveshare.vsliveshare
prettier.prettier-vscode
```

### Environment Variables
Customize via deployment environment:
```yaml
env:
- name: DEFAULT_WORKSPACE
  value: "/home/coder/projects"
- name: CODE_SERVER_CERT
  value: "false"
```

### Port Forwarding
Access development servers:
```bash
# Forward local development server
kubectl port-forward -n code-server deployment/code-server 3000:3000
```

This provides a complete, secure, and feature-rich development environment accessible from anywhere.