# Download Client Proxy Configuration

## IMPORTANT: Manual Configuration Required
Since network policies are not being enforced (Flannel doesn't support them without a controller), you MUST manually configure proxy settings in each download client.

## Gluetun Proxy Details
- **SOCKS5 Host**: `gluetun.gluetun.svc.cluster.local`
- **SOCKS5 Port**: `1080` (or `8388` for direct Shadowsocks)
- **HTTP Proxy Host**: `gluetun.gluetun.svc.cluster.local`
- **HTTP Proxy Port**: `8888`
- **Shadowsocks Password**: `gluetun` (if using port 8388 directly)

## qBittorrent Configuration

1. Access qBittorrent WebUI: https://qbittorrent.k8s.dttesting.com
2. Go to **Tools** → **Options** → **Connection**
3. In the **Proxy Server** section:
   - **Type**: `SOCKS5`
   - **Host**: `gluetun.gluetun.svc.cluster.local`
   - **Port**: `1080`
   - **Authentication**: Leave unchecked (not required)
   - **Use proxy for peer connections**: ✓ Check this
   - **Disable connections not supported by proxies**: ✓ Check this
   - **Use proxy only for torrents**: ✗ Uncheck (proxy everything)
4. Click **Apply** and **OK**

### Verify qBittorrent is using VPN:
1. Go to **Tools** → **Options** → **Advanced**
2. Check **Network Interface**: Should show VPN interface if bound
3. Or download a torrent from https://ipleak.net/torrent-test to verify VPN IP

## NZBget Configuration

1. Access NZBget WebUI: https://nzbget.k8s.dttesting.com
2. Default login: `admin` / `admin123!`
3. Go to **Settings** → **Connection**
4. Find the **Proxy** section:
   - **ArticleProxy**: `gluetun.gluetun.svc.cluster.local:1080`
   - **ArticleProxyType**: `socks5`
   - **ArticleProxyAuth**: `no`
5. Click **Save all changes**
6. Go to **System** → **Reload**

### Verify NZBget is using VPN:
Check the logs for connection attempts - they should go through the proxy.

## Testing VPN Protection

### From inside the cluster:
```bash
# Test without proxy (should show real IP)
kubectl exec -n downloads deployment/qbittorrent -- curl -s http://ifconfig.me

# Test with proxy (should show VPN IP)
kubectl exec -n downloads deployment/qbittorrent -- curl -s --socks5 gluetun.gluetun.svc.cluster.local:1080 http://ifconfig.me
```

### Expected Results:
- Without proxy: Shows your ISP IP (24.17.117.107) - BAD
- With proxy: Shows Mullvad VPN IP - GOOD

## Troubleshooting

### If proxy connection fails:
1. Check Gluetun is running: `kubectl get pods -n gluetun`
2. Check proxy logs: `kubectl logs -n gluetun deployment/gluetun | grep -i proxy`
3. Test connectivity: `kubectl exec -n downloads deployment/qbittorrent -- nc -zv gluetun.gluetun.svc.cluster.local 1080`

### If downloads are slow:
- This is normal when using VPN
- Check Gluetun logs for connection issues
- Consider using HTTP proxy (port 8888) for HTTP/HTTPS downloads only