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

## Certificate Management

### cert-manager Webhook Errors

**Symptom**: 
```
failed calling webhook "webhook.cert-manager.io": x509: certificate signed by unknown authority
```

**Cause**: Webhook certificate not properly injected

**Solution**:
1. Delete and recreate webhook:
   ```bash
   kubectl delete validatingwebhookconfiguration cert-manager-webhook
   kubectl apply -k kubernetes/core/cert-manager/
   ```
2. Restart cert-manager:
   ```bash
   kubectl rollout restart deployment -n cert-manager
   ```

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