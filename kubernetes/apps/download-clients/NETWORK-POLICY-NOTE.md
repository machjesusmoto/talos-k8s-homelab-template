# Network Policy Implementation Note

## Current Status
Network policies have been created but are NOT being enforced because the cluster is using Flannel CNI without a network policy controller.

## Issue
- Flannel by itself does not enforce NetworkPolicy resources
- Download clients can still access the internet directly, bypassing the VPN
- The `gluetun.io/enabled` annotation was not actually implementing sidecar injection

## Required Actions
To properly enforce VPN usage, one of the following must be done:

1. **Install a Network Policy Controller** (Recommended)
   - Add Calico in policy-only mode to work with Flannel
   - Or install kube-router as a network policy controller
   
2. **Switch CNI to Cilium**
   - Replace Flannel with Cilium which has built-in network policy support
   - Requires cluster reconfiguration

3. **Manual Proxy Configuration** (Current Workaround)
   - Configure each download client to use Gluetun's SOCKS5 proxy
   - qBittorrent: Settings -> Connection -> Proxy Server
     - Type: SOCKS5
     - Host: gluetun.gluetun.svc.cluster.local
     - Port: 1080
   - NZBget: Settings -> Connection -> Proxy
     - Similar configuration

## Security Risk
Until network policies are enforced or proxy settings are manually configured, download clients are using your real IP address (24.17.117.107) instead of the VPN.