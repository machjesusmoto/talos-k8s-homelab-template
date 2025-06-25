# Troubleshooting Guide

This comprehensive guide covers common issues and their solutions for the Talos Kubernetes homelab deployment.

## Table of Contents
- [Cluster Deployment Issues](#cluster-deployment-issues)
- [Network Connectivity Problems](#network-connectivity-problems)
- [ArgoCD and GitOps Issues](#argocd-and-gitops-issues)
- [Certificate Management](#certificate-management)
- [Storage Issues](#storage-issues)
- [Diagnostic Tools](#diagnostic-tools)

## Cluster Deployment Issues

### Bootstrap Timeout with VIP Error

**Symptom**: 
```
error bootstrapping cluster: rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing: dial tcp 192.168.1.240:6443: connect: no route to host"
```

**Cause**: VIP misconfiguration or network interface issues

**Solution**:
1. Verify network interface name:
   ```bash
   talosctl get interfaces -n <node-ip>
   ```
2. Ensure `talos/patches/controlplane.yaml` has correct configuration:
   ```yaml
   network:
     interfaces:
       - deviceSelector:
           driver: virtio_net
         dhcp: true
         vip:
           ip: 192.168.1.240
   ```
3. Reapply configurations and bootstrap again

### Node Stuck in Maintenance Mode

**Symptom**: Nodes don't join cluster after configuration

**Cause**: ISO still attached or configuration not applied

**Solution**:
1. Check if ISO is ejected:
   ```powershell
   # Windows
   .\scripts\cluster-exec.ps1 all "df -h | grep sr0"
   ```
2. If ISO still mounted, manually eject in Proxmox
3. Reboot node to apply configuration

### Certificate Verification Errors

**Symptom**: 
```
x509: certificate signed by unknown authority
```

**Cause**: Nodes not properly configured or certificates not synced

**Solution**:
1. Verify all nodes are using same `secrets.yaml`
2. Check node configuration:
   ```bash
   talosctl get machineconfig -n <node-ip>
   ```
3. Reapply configuration if needed

## Network Connectivity Problems

### Pods Can't Reach Kubernetes API

**Symptom**: 
```
dial tcp 10.96.0.1:443: i/o timeout
```

**Cause**: kube-proxy not deployed when Talos has `proxy.disabled: true`

**Solution**:
1. Deploy core infrastructure including kube-proxy:
   ```bash
   kubectl apply -k kubernetes/core/
   ```
2. Verify kube-proxy is running:
   ```bash
   kubectl get pods -n kube-system | grep kube-proxy
   ```

### MetalLB Not Assigning IPs

**Symptom**: LoadBalancer services stuck in `<pending>`

**Cause**: MetalLB not configured or IP pool exhausted

**Solution**:
1. Check MetalLB status:
   ```bash
   kubectl get pods -n metallb-system
   kubectl get ipaddresspool -n metallb-system
   ```
2. Verify IP pool configuration:
   ```bash
   kubectl describe ipaddresspool -n metallb-system
   ```
3. Check for IP conflicts in network

### DNS Resolution Failures

**Symptom**: Pods can't resolve external domains

**Cause**: CoreDNS issues or network policies

**Solution**:
1. Test DNS from a pod:
   ```bash
   kubectl run test-dns --image=busybox:1.28 --rm -it -- nslookup kubernetes.default
   ```
2. Check CoreDNS logs:
   ```bash
   kubectl logs -n kube-system deployment/coredns
   ```

## ArgoCD and GitOps Issues

### ArgoCD Server Crashing

**Symptom**: ArgoCD server pod in CrashLoopBackOff

**Cause**: Configuration error or resource constraints

**Solution**:
1. Check logs:
   ```bash
   kubectl logs -n argocd deployment/argocd-server
   ```
2. Verify configuration:
   ```bash
   kubectl describe deployment -n argocd argocd-server
   ```
3. Increase resources if needed

### Application Sync Failures

**Symptom**: ArgoCD applications show as "OutOfSync" or "Unknown"

**Cause**: Git repository access issues or invalid manifests

**Solution**:
1. Check application status:
   ```bash
   kubectl get applications -n argocd
   kubectl describe application <app-name> -n argocd
   ```
2. Verify Git repository is accessible
3. Validate Kubernetes manifests locally

### ArgoCD Can't Access Git Repository

**Symptom**: "Repository not accessible" errors

**Solution**:
1. For public repos, ensure URL is correct
2. For private repos, add SSH key or token:
   ```bash
   argocd repo add <repo-url> --username <username> --password <token>
   ```

### Kustomization Build Errors

**Symptom**: "Failed to load target state: failed to generate manifest"

**Cause**: Duplicate namespace definitions or invalid kustomization.yaml

**Solution**:
1. Check for duplicate namespace definitions:
   ```bash
   # Look for namespaces created by external manifests
   grep -r "kind: Namespace" kubernetes/core/
   ```
2. Remove duplicate namespaces from `namespaces.yaml` if external manifests create them
3. Common duplicates: metallb-system, cert-manager, ingress-nginx

### ArgoCD Login Issues with CLI

**Symptom**: "EOF" error or TLS prompts when using argocd CLI

**Solution**:
1. Use echo to auto-accept insecure connection:
   ```bash
   echo y | ~/bin/argocd login 192.168.1.210 --username admin --password 'your-password' --insecure --grpc-web
   ```
2. For HTTP-only setups, always use `--grpc-web` flag

### Existing Resources Conflict

**Symptom**: "resource already exists" during ArgoCD sync

**Cause**: Resources manually deployed before GitOps

**Solution**:
1. Import existing resources with force sync:
   ```bash
   ~/bin/argocd app sync <app-name> --force
   ```
2. Or delete existing resources and let ArgoCD recreate:
   ```bash
   kubectl delete -k kubernetes/core/
   ~/bin/argocd app sync core-infrastructure
   ```

### PVC Storage Class Immutable Error

**Symptom**: 
```
PersistentVolumeClaim "app-data" is invalid: spec: Forbidden: spec is immutable after creation except resources.requests and volumeAttributesClassName for bound claims
core.PersistentVolumeClaimSpec{
  StorageClassName: &"",
+ StorageClassName: &"nfs-apps",
}
```

**Cause**: Application PVCs were created with different storage class (often empty `""`) but configuration now specifies a different storage class

**Root Cause**: Kubernetes doesn't allow changing the storage class of existing PVCs - this field is immutable

**Solution**:
1. **Delete the application deployments** to release PVC locks:
   ```bash
   kubectl delete deployment <app-name> -n <namespace>
   ```
2. **Delete the problematic PVCs**:
   ```bash
   kubectl delete pvc <pvc-name> -n <namespace>
   ```
3. **Wait for PVCs and PVs to fully terminate**:
   ```bash
   kubectl get pvc -n <namespace>
   kubectl get pv | grep <namespace>
   ```
4. **Trigger application sync** to recreate with correct storage class:
   ```bash
   ~/bin/argocd app sync <app-name>
   ```

**Example - RustDesk Storage Class Fix**:
```bash
# Delete deployments to release PVCs
kubectl delete deployment rustdesk-hbbr rustdesk-hbbs -n rustdesk

# Delete stuck PVCs
kubectl delete pvc rustdesk-hbbr-data rustdesk-hbbs-data -n rustdesk

# Verify cleanup
kubectl get pvc -n rustdesk
kubectl get pv | grep rustdesk

# Sync to recreate with correct storage class
~/bin/argocd app sync rustdesk
```

**Prevention**:
- Always specify the correct storage class in initial deployment
- Use consistent storage classes across all applications
- Test storage configurations before production deployment

### ArgoCD Authentication and Password Issues

**Symptom**: Unable to login to ArgoCD web UI or password changes don't persist

**Cause**: Authentication system issues due to incomplete or corrupted `argocd-secret` configuration

**Root Cause Analysis**:
- ArgoCD requires both `argocd-secret` (with `server.secretkey`) and `argocd-initial-admin-secret` for proper authentication
- The dex-server component crashes if `argocd-secret` is missing the required `server.secretkey`
- Manually setting password hashes without proper secret structure can cause authentication failures
- Component synchronization issues between server, dex-server, and repo-server

**Complete Password Reset Solution**:

1. **Delete all authentication secrets**:
   ```bash
   kubectl delete secret argocd-initial-admin-secret -n argocd
   kubectl delete secret argocd-secret -n argocd
   ```

2. **Create properly structured argocd-secret**:
   ```bash
   kubectl create secret generic argocd-secret -n argocd \
     --from-literal=server.secretkey=$(openssl rand -base64 32)
   ```

3. **Restart all ArgoCD components**:
   ```bash
   kubectl rollout restart deployment argocd-server -n argocd
   kubectl rollout restart deployment argocd-dex-server -n argocd
   kubectl rollout restart deployment argocd-repo-server -n argocd
   ```

4. **Wait for components to be ready**:
   ```bash
   kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=120s
   ```

5. **Get new initial admin password**:
   ```bash
   kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
   ```

6. **Login and change password**:
   - Access ArgoCD UI at http://192.168.1.210
   - Username: `admin`
   - Password: (output from step 5)
   - Change password through UI: User Info → Update Password

**Prevention**:
- Always ensure `argocd-secret` contains `server.secretkey` when manually managing secrets
- Use ArgoCD UI for password changes rather than direct secret manipulation
- Monitor dex-server pod status when making authentication changes

## Certificate Management

### cert-manager Webhook Errors

**Symptom**: 
```
failed calling webhook "webhook.cert-manager.io": x509: certificate signed by unknown authority
```

**Cause**: Webhook certificate not properly injected or webhook configuration corrupted

**Solution**:
1. Delete webhook configurations:
   ```bash
   kubectl delete validatingwebhookconfiguration cert-manager-webhook
   kubectl delete mutatingwebhookconfiguration cert-manager-webhook
   ```
2. Reapply cert-manager to restore configurations:
   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.yaml
   ```
3. Wait for webhook to be ready:
   ```bash
   kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=webhook -n cert-manager --timeout=60s
   ```
4. Temporarily disable webhook validation if needed:
   ```bash
   kubectl annotate validatingwebhookconfiguration cert-manager-webhook cert-manager.io/disable-validation=true
   # Apply ClusterIssuers
   kubectl annotate validatingwebhookconfiguration cert-manager-webhook cert-manager.io/disable-validation-
   ```

### DNS-01 Challenge Issues

**Symptom**: 
```
Error: 6003: Invalid request headers<- 6111: Invalid format for Authorization header
```

**Cause**: Malformed Cloudflare API token (often trailing quotes or spaces)

**Solution**:
1. Check the API token secret:
   ```bash
   kubectl get secret cloudflare-api-token-secret -n cert-manager -o jsonpath='{.data.api-token}' | base64 -d
   ```
2. Fix the token if it has extra characters:
   ```bash
   kubectl patch secret cloudflare-api-token-secret -n cert-manager --type='json' \
     -p='[{"op": "replace", "path": "/data/api-token", "value": "'$(echo -n 'CLEAN_TOKEN_HERE' | base64 -w0)'"}]'
   ```
3. Delete and recreate certificates to retry:
   ```bash
   kubectl delete certificate <cert-name> -n <namespace>
   kubectl apply -f <certificate-file>
   ```

### Challenge Stuck in Pending

**Symptom**: DNS challenge remains pending for >5 minutes

**Cause**: DNS propagation delays or API permission issues

**Solution**:
1. Check challenge details:
   ```bash
   kubectl describe challenge <challenge-name> -n <namespace>
   ```
2. Verify API token permissions in Cloudflare
3. Check DNS propagation:
   ```bash
   dig _acme-challenge.your-domain.com TXT
   ```
4. Wait for propagation (can take up to 10 minutes)

### DNS-01 Challenge with Split-Brain DNS (Common Homelab Issue)

**Symptom**: Challenge shows "DNS record not yet propagated" despite correct Cloudflare configuration

**Cause**: Internal DNS (Unbound, pfSense, etc.) intercepting queries for your domain instead of forwarding to Cloudflare

**Solution**:
1. **Identify the issue**: Your domain (e.g., `dttesting.com`) is configured as an internal domain, causing DNS queries to be resolved locally instead of via Cloudflare
2. **Configure DNS forwarding** for your subdomain to Cloudflare:
   
   **For Unbound DNS**:
   ```
   # Add to Unbound configuration
   forward-zone:
       name: "k8s.dttesting.com"
       forward-addr: 1.1.1.1
       forward-addr: 1.0.0.1
   ```
   
   **For pfSense DNS Resolver**:
   - Navigate to Services > DNS Resolver > General Settings
   - Add Domain Override: 
     - Domain: `k8s.dttesting.com`
     - IP: `1.1.1.1`
   
3. **Test DNS resolution after configuration**:
   ```bash
   # Test from inside your network
   dig _acme-challenge.app.k8s.dttesting.com TXT
   # Should return Cloudflare result, not NXDOMAIN
   ```

4. **Restart certificate process**:
   ```bash
   # Delete existing certificate to force new challenge
   kubectl delete certificate <cert-name> -n <namespace>
   # Certificate will be automatically recreated by ingress
   ```

**Alternative Solutions**:
- Use a different subdomain that's not managed internally
- Configure your internal DNS to not override the subdomain
- Use HTTP-01 challenge instead (requires port 80 external access)

### Let's Encrypt Rate Limits

**Symptom**: Certificate requests failing with rate limit errors

**Solution**:
1. Use staging issuer for testing:
   ```yaml
   server: https://acme-staging-v02.api.letsencrypt.org/directory
   ```
2. Check existing certificates:
   ```bash
   kubectl get certificates -A
   ```

## Storage Issues

### NFS CSI Driver Pod Security Violations

**Symptom**: NFS CSI pods fail to start due to security policies

**Solution**:
1. Ensure namespace has proper security policy:
   ```bash
   kubectl label namespace nfs-csi pod-security.kubernetes.io/enforce=privileged
   ```
2. Verify with:
   ```bash
   kubectl get namespace nfs-csi -o yaml | grep pod-security
   ```

### PVC Stuck in Pending

**Symptom**: PersistentVolumeClaims not binding

**Solution**:
1. Check storage class:
   ```bash
   kubectl get storageclass
   kubectl describe pvc <pvc-name>
   ```
2. Verify NFS CSI driver is running:
   ```bash
   kubectl get pods -n nfs-csi
   ```

## Diagnostic Tools

### Windows PowerShell Scripts

```powershell
# Comprehensive cluster diagnosis
.\scripts\diagnose-cluster.ps1

# Execute commands across nodes
.\scripts\cluster-exec.ps1 all "talosctl service"
.\scripts\cluster-exec.ps1 cp "talosctl logs -k kubelet | tail -50"
```

### Linux/macOS Scripts

```bash
# Execute commands across nodes
./scripts/cluster-exec.sh all "talosctl service"
./scripts/cluster-exec.sh workers "df -h"
```

### Useful Talos Commands

```bash
# Check node health
talosctl health -n <node-ip>

# View system services
talosctl service -n <node-ip>

# Check kubelet logs
talosctl logs -n <node-ip> -k kubelet

# View etcd status (control planes only)
talosctl etcd status -n <control-plane-ip>

# Check cluster membership
talosctl get members -n <node-ip>
```

### Kubernetes Debugging

```bash
# Check all pods not running
kubectl get pods -A | grep -v Running

# Describe problematic pod
kubectl describe pod <pod-name> -n <namespace>

# Check events
kubectl get events -A --sort-by='.lastTimestamp'

# View node conditions
kubectl get nodes -o wide
kubectl describe node <node-name>
```

## Recovery Procedures

### Complete Cluster Recovery

If cluster is completely broken:

1. **Reboot all nodes from ISO**
2. **Regenerate configurations**:
   ```bash
   ./scripts/generate-configs.sh  # Linux
   .\scripts\generate-configs.ps1  # Windows
   ```
3. **Apply configurations**:
   ```bash
   ./scripts/apply-configs.sh  # Linux
   .\scripts\apply-configs.ps1  # Windows
   ```
4. **Bootstrap cluster**:
   ```bash
   ./scripts/bootstrap-cluster.sh  # Linux
   .\scripts\bootstrap-cluster.ps1  # Windows
   ```

### Single Node Recovery

If single node is problematic:

1. **Reset the node**:
   ```bash
   talosctl reset --graceful=false -n <node-ip>
   ```
2. **Reapply configuration**:
   ```bash
   talosctl apply-config -n <node-ip> -f <config-file>
   ```

## Getting Help

### Logs Collection

Collect comprehensive logs for troubleshooting:

```bash
# Node logs
talosctl support -n <node-ip> -O logs/

# Kubernetes logs
kubectl cluster-info dump --output-directory=logs/

# ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=100
```

### Community Resources

- Talos Linux Slack: https://slack.dev.talos-systems.io
- Kubernetes Slack: https://kubernetes.slack.com
- ArgoCD Slack: https://argoproj.github.io/community/join-slack/

### Documentation

- Talos Docs: https://www.talos.dev/
- Kubernetes Docs: https://kubernetes.io/docs/
- ArgoCD Docs: https://argo-cd.readthedocs.io/