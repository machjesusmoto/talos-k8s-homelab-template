# Session Context - July 9, 2025

## Current Status
- **Cluster**: 5-node Talos Linux Kubernetes cluster fully operational
- **Nodes**: All healthy - 3 control plane (cp-01/02/03) + 2 workers (worker-01/02)  
- **Applications**: 55 pods running across all nodes
- **Storage**: NFS working correctly after fixing thread limits and permissions
- **GitOps**: ArgoCD managing infrastructure

## Recent Accomplishments
1. **NFS Issues Resolved**: Fixed CSI conflicts, TrueNAS threads (6→24), dataset permissions
2. **Hardware Maintenance**: Successfully performed cluster shutdown/startup with new scripts
3. **Node Recovery**: Reset and rejoined cp-02 and worker-02 to cluster
4. **Full Restoration**: All 5 nodes operational with applications distributed

## Key Technical Details
- **VIP**: 192.168.1.240 (control plane endpoint)
- **Node IPs**: 192.168.1.241-245 (cp-01/02/03, worker-01/02)
- **NFS**: TrueNAS with 24 threads, root:root permissions, NFSv4.2
- **Interface**: `ens18` (Proxmox VMs)
- **Config Files**: `talos/controlplane-{1,2,3}.yaml`, `talos/worker-{1,2}.yaml`

## Pending Tasks (from todo list)
1. **Fix VPN connectivity for download clients** (Medium priority) - WireGuard config needs validation
2. **Fix network connectivity to lscr.io registry** (Medium priority) - ImagePullBackOff issues
3. **Fix readarr image compatibility issue** (Low priority)

## Recent Fixes Applied
1. **LinuxServer Containers Security** ✅ COMPLETED
   - Added SETUID/SETGID capabilities to Prowlarr, Radarr, Sonarr, Lidarr, Bazarr, NZBGet
   - Set privileged pod security on automation, media, downloads namespaces
   - Created automation scripts: fix-linuxserver-security.sh/ps1
   - Fixed CrashLoopBackOff errors with s6-overlay permission issues

## Next Focus Areas
1. **VPN Configuration**: Setup Gluetun/WireGuard for download clients
2. **Application Issues**: Resolve any remaining app problems
3. **Monitoring**: Verify all services are healthy
4. **Documentation**: Continue improving deployment guides

## Important Files
- `/scripts/cluster-shutdown.sh|ps1` - Graceful shutdown
- `/scripts/cluster-startup.sh|ps1` - Startup and app scaling
- `/scripts/apply-configs.sh|ps1` - Node configuration
- `/configurations.yaml` - Master config with secrets
- `/CLAUDE.md` - Project documentation (updated)

## Commands for Next Session
```bash
# Check cluster health
kubectl get nodes
kubectl get pods -A | grep -v Running

# VPN work
kubectl logs -n gluetun gluetun-<pod> 
kubectl describe deployment gluetun -n gluetun

# Application status
kubectl get deployments -A --no-headers | grep " 0/"
```

**Ready to continue with VPN configuration and remaining tasks.**