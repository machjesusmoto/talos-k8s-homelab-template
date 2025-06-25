# Troubleshooting Guide - Ultimate Life Automation Platform

This comprehensive guide covers common issues and their solutions for the complete life automation platform deployment.

## Table of Contents
- [Cluster Deployment Issues](#cluster-deployment-issues)
- [Network Connectivity Problems](#network-connectivity-problems)
- [ArgoCD and GitOps Issues](#argocd-and-gitops-issues)
- [Application-Specific Issues](#application-specific-issues)
- [Certificate Management](#certificate-management)
- [Storage Issues](#storage-issues)
- [VPN and Security Issues](#vpn-and-security-issues)
- [Performance and Resource Issues](#performance-and-resource-issues)
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
1. Check if ISO is ejected from Proxmox
2. Restart VMs to boot from disk
3. Reapply configuration if needed:
   ```bash
   talosctl apply-config --insecure --nodes <node-ip> --file talos/controlplane.yaml
   ```

### Certificate Verification Errors

**Symptom**: `x509: certificate signed by unknown authority`

**Cause**: Nodes not properly configured or clock synchronization issues

**Solution**:
1. Verify all nodes are configured and running from disk
2. Check time synchronization on all nodes
3. Regenerate certificates if necessary:
   ```bash
   ./scripts/generate-configs.sh
   ```

## Application-Specific Issues

### LinuxServer Container Permission Issues

**Symptom**: 
```
s6-applyuidgid: fatal: unable to set supplementary group list: Operation not permitted
```

**Affected Applications**: Sonarr, Radarr, Lidarr, Bazarr, Readarr, qBittorrent, NZBget, Grocy

**Cause**: Pod security policies preventing proper user ID management

**Solution**:
1. Verify namespace has privileged pod security labels:
   ```yaml
   metadata:
     labels:
       pod-security.kubernetes.io/enforce: privileged
       pod-security.kubernetes.io/audit: privileged
       pod-security.kubernetes.io/warn: privileged
   ```
2. Containers are configured to run as root:
   ```yaml
   securityContext:
     runAsNonRoot: false
     runAsUser: 0
     runAsGroup: 0
   ```
3. Wait for containers to complete initialization (may take 2-3 minutes)

### PVC Storage Class Immutable Error

**Symptom**: 
```
PersistentVolumeClaim "app-data" is invalid: spec: Forbidden: spec is immutable after creation except resources.requests for bound claims
```

**Cause**: Trying to change storage class of existing PVC

**Solution**:
1. Delete the application deployment:
   ```bash
   kubectl delete deployment <app-name> -n <namespace>
   ```
2. Delete the problematic PVC:
   ```bash
   kubectl delete pvc <pvc-name> -n <namespace>
   ```
3. Trigger ArgoCD sync to recreate with correct storage class:
   ```bash
   kubectl patch application <app-name> -n argocd -p '{"operation":{"sync":{}}}' --type=merge
   ```

### Media Management (*arr) Configuration Issues

**Symptom**: Applications not finding shared media storage

**Solution**:
1. Verify media storage PVC is bound:
   ```bash
   kubectl get pvc -n media
   ```
2. Check mount paths in deployments:
   ```bash
   kubectl exec -n media deployment/sonarr -- ls -la /media
   ```
3. Ensure proper permissions:
   ```bash
   kubectl exec -n media deployment/sonarr -- chown -R 1000:1000 /media
   ```

### Download Client Connectivity Issues

**Symptom**: *arr applications can't connect to download clients

**Solution**:
1. Test internal DNS resolution:
   ```bash
   kubectl exec -n media deployment/sonarr -- nslookup qbittorrent.downloads.svc.cluster.local
   ```
2. Verify download client credentials
3. Check service endpoints:
   ```bash
   kubectl get endpoints -n downloads
   ```

### Notification Issues (Notifiarr)

**Symptom**: No notifications received from automation

**Solution**:
1. Verify Notifiarr API key configuration:
   ```bash
   kubectl get secret notifiarr-secrets -n notifications -o yaml
   ```
2. Check application connectivity:
   ```bash
   kubectl exec -n notifications deployment/notifiarr -- curl http://sonarr.media.svc.cluster.local:8989/api/v3/system/status
   ```
3. Test Discord webhook:
   ```bash
   kubectl logs -n notifications deployment/notifiarr | grep -i discord
   ```

### Document Management (Paperless-ngx) Issues

**Symptom**: Paperless containers failing to start

**Solution**:
1. Check PostgreSQL connectivity:
   ```bash
   kubectl exec -n paperless deployment/paperless-ngx -- pg_isready -h postgres -U paperless
   ```
2. Verify Redis connectivity:
   ```bash
   kubectl exec -n paperless deployment/paperless-ngx -- redis-cli -h redis ping
   ```
3. Check container logs for specific errors:
   ```bash
   kubectl logs -n paperless deployment/paperless-ngx -c paperless
   ```

### Household Management (Grocy) Issues

**Symptom**: Grocy web interface not accessible

**Solution**:
1. Check PHP-FPM and Nginx logs:
   ```bash
   kubectl logs -n household deployment/grocy
   ```
2. Verify database permissions:
   ```bash
   kubectl exec -n household deployment/grocy -- ls -la /config/data/
   ```
3. Test web service internally:
   ```bash
   kubectl exec -n household deployment/grocy -- curl http://localhost
   ```

## VPN and Security Issues

### Gluetun VPN Connection Problems

**Symptom**: Download clients can't access the internet

**Solution**:
1. Check Gluetun status:
   ```bash
   kubectl logs -n gluetun deployment/gluetun -f
   ```
2. Verify VPN credentials configuration
3. Test IP from download clients:
   ```bash
   kubectl exec -n downloads deployment/qbittorrent -- curl ifconfig.me
   ```

### SSL Certificate Issues

**Symptom**: Browser warnings about invalid certificates

**Solution**:
1. Check cert-manager status:
   ```bash
   kubectl get certificates -A
   ```
2. Verify Let's Encrypt challenges:
   ```bash
   kubectl describe challenge -A
   ```
3. Check Traefik configuration:
   ```bash
   kubectl logs -n traefik deployment/traefik
   ```

## Performance and Resource Issues

### High Memory Usage

**Symptom**: Applications being killed due to memory limits

**Solution**:
1. Check resource usage:
   ```bash
   kubectl top pods -A --sort-by=memory
   ```
2. Increase memory limits for heavy applications:
   ```yaml
   resources:
     limits:
       memory: "4Gi"  # Increase as needed
   ```
3. Monitor with Grafana dashboards

### Storage Space Issues

**Symptom**: Applications failing due to insufficient storage

**Solution**:
1. Check PVC usage:
   ```bash
   kubectl exec -n <namespace> deployment/<app> -- df -h
   ```
2. Clean up old data:
   ```bash
   # Example for download clients
   kubectl exec -n downloads deployment/qbittorrent -- find /downloads -type f -mtime +30 -delete
   ```
3. Expand PVC if needed:
   ```bash
   kubectl patch pvc <pvc-name> -n <namespace> -p '{"spec":{"resources":{"requests":{"storage":"200Gi"}}}}'
   ```

### Network Performance Issues

**Symptom**: Slow download speeds or timeouts

**Solution**:
1. Check network policies:
   ```bash
   kubectl get networkpolicies -A
   ```
2. Monitor network metrics in Grafana
3. Test bandwidth between pods:
   ```bash
   kubectl exec -n downloads deployment/qbittorrent -- iperf3 -c <target-ip>
   ```

## Diagnostic Tools

### Cluster Health Check

```bash
# Complete cluster status
kubectl get nodes -o wide
kubectl get pods -A --field-selector=status.phase!=Running
kubectl top nodes
kubectl top pods -A --sort-by=memory

# Storage overview
kubectl get pv,pvc -A

# Network services
kubectl get services -A
kubectl get ingress -A
```

### Application Health Check

```bash
# Check all applications
kubectl get applications -n argocd

# Specific application status
kubectl describe application <app-name> -n argocd

# Pod logs for troubleshooting
kubectl logs -n <namespace> deployment/<app-name> --tail=50 -f
```

### Network Diagnostics

```bash
# DNS resolution test
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Internal connectivity test
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://<service>.<namespace>.svc.cluster.local

# External connectivity test
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl https://google.com
```

### Storage Diagnostics

```bash
# NFS server connectivity
kubectl exec -n <namespace> deployment/<app> -- showmount -e <nfs-server-ip>

# Mount point verification
kubectl exec -n <namespace> deployment/<app> -- mount | grep nfs

# File system permissions
kubectl exec -n <namespace> deployment/<app> -- ls -la /path/to/mount
```

### Resource Monitoring

```bash
# Real-time resource usage
watch kubectl top pods -A

# Event monitoring
kubectl get events -A --sort-by=lastTimestamp

# Resource quotas and limits
kubectl describe resourcequota -A
kubectl describe limitrange -A
```

## Emergency Recovery Procedures

### Cluster Recovery

If the cluster becomes unresponsive:

1. **Check node status**:
   ```bash
   talosctl health --endpoints 192.168.1.241,192.168.1.242,192.168.1.243
   ```

2. **Restart problematic nodes**:
   ```bash
   talosctl reboot -n <node-ip>
   ```

3. **Re-bootstrap if necessary**:
   ```bash
   talosctl bootstrap -n 192.168.1.241
   ```

### Application Recovery

If applications are in a bad state:

1. **Restart specific application**:
   ```bash
   kubectl rollout restart deployment/<app-name> -n <namespace>
   ```

2. **Force ArgoCD sync**:
   ```bash
   kubectl patch application <app-name> -n argocd -p '{"operation":{"sync":{"prune":true}}}' --type=merge
   ```

3. **Complete application reset**:
   ```bash
   kubectl delete application <app-name> -n argocd
   kubectl apply -f kubernetes/gitops/applications/<app-name>.yaml
   ```

### Data Recovery

For critical data loss scenarios:

1. **Restore from NFS snapshots** (if configured)
2. **Restore application-specific backups**:
   ```bash
   # Example for Paperless-ngx
   kubectl exec -n paperless deployment/paperless-ngx -- tar -xzf /path/to/backup.tar.gz -C /config
   ```

3. **Database recovery**:
   ```bash
   # Example for PostgreSQL
   kubectl exec -n paperless deployment/postgres -- psql -U paperless -d paperless < backup.sql
   ```

This troubleshooting guide covers the most common issues encountered with the complete life automation platform. For additional support, check application-specific README files in each kubernetes/apps/ directory.