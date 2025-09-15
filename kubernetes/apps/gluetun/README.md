# Gluetun VPN Gateway

Gluetun provides a VPN gateway that other containers can route traffic through for secure, anonymous internet access.

## Features

- **Multiple VPN providers** supported (Mullvad, NordVPN, ExpressVPN, Surfshark, PIA, etc.)
- **Kill switch** - blocks traffic if VPN disconnects
- **DNS over TLS** with Cloudflare for secure DNS
- **HTTP and SOCKS5 proxy** for applications
- **Health monitoring** with web interface
- **Firewall protection** with customizable rules

## Setup Instructions

### 1. Configure VPN Credentials

Copy the secret template and add your VPN credentials:

```bash
cp secret-template.yaml secret.yaml
```

Edit `secret.yaml` with your VPN provider credentials:

#### For Mullvad (Recommended)
```yaml
stringData:
  WIREGUARD_PRIVATE_KEY: "your-wireguard-private-key"
  WIREGUARD_ADDRESSES: "10.x.x.x/32"  # From Mullvad config
```

#### For Username/Password Providers
```yaml
stringData:
  VPN_USERNAME: "your-username"
  VPN_PASSWORD: "your-password"
```

### 2. Update Configuration

Edit `configmap.yaml` to match your VPN provider:

```yaml
data:
  VPN_SERVICE_PROVIDER: "mullvad"  # Change to your provider
  VPN_TYPE: "wireguard"            # or "openvpn"
```

### 3. Apply Secret Manually

Since secrets are gitignored, apply manually:

```bash
kubectl apply -f secret.yaml
```

### 4. Deploy via ArgoCD

The application will be automatically deployed via ArgoCD once committed to Git.

## Accessing Gluetun

- **Health Interface**: https://gluetun.k8s.dttesting.com
- **HTTP Proxy**: `gluetun.gluetun.svc.cluster.local:8888`
- **SOCKS5 Proxy**: `gluetun.gluetun.svc.cluster.local:8388`

## Using Gluetun with Other Applications

### Method 1: Shared Network Namespace
Deploy containers in the same pod to share the VPN connection:

```yaml
spec:
  template:
    spec:
      containers:
      - name: gluetun
        image: qmcgaw/gluetun
        # ... gluetun config
      - name: your-app
        image: your-app:latest
        # This container will route through gluetun
```

### Method 2: HTTP/SOCKS Proxy
Configure applications to use gluetun as a proxy:

```yaml
env:
- name: HTTP_PROXY
  value: "http://gluetun.gluetun.svc.cluster.local:8888"
- name: HTTPS_PROXY
  value: "http://gluetun.gluetun.svc.cluster.local:8888"
```

## VPN Provider Setup

### Mullvad (Recommended)
1. Sign up at https://mullvad.net
2. Generate WireGuard configuration
3. Extract private key and addresses from config
4. Add to secret.yaml

### NordVPN
1. Enable "NordLynx" (WireGuard) in account settings
2. Use username/password or private key authentication
3. Update configmap with `VPN_SERVICE_PROVIDER: "nordvpn"`

### Other Providers
Check [gluetun documentation](https://github.com/qdm12/gluetun) for provider-specific setup.

## Monitoring

- **Health endpoint**: Check VPN status and public IP
- **Logs**: `kubectl logs -n gluetun deployment/gluetun`
- **IP check**: Visit health interface to verify external IP

## Security Features

- **Kill switch**: Blocks all traffic if VPN disconnects
- **DNS leak protection**: Uses encrypted DNS over TLS
- **Firewall rules**: Only allows traffic through VPN tunnel
- **No logs**: Traffic routing without logging

## Troubleshooting

### VPN Not Connecting
```bash
# Check logs
kubectl logs -n gluetun deployment/gluetun

# Verify credentials
kubectl get secret gluetun-vpn-secret -n gluetun -o yaml

# Test configuration
kubectl exec -n gluetun deployment/gluetun -- wget -qO- https://ipinfo.io
```

### Performance Issues
- Reduce `replicas` to 1 (VPN containers should not be scaled)
- Check CPU/memory limits
- Try different VPN servers/locations

### Applications Not Using VPN
- Verify proxy configuration
- Check network policies
- Ensure applications support HTTP_PROXY environment variables