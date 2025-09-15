# Private Internet Access (PIA) Setup for Gluetun

## Important: Use OpenVPN, Not WireGuard

**PIA WireGuard requires manual token generation** which is not natively supported in Gluetun yet. Use OpenVPN for simpler setup.

## Why OpenVPN is Recommended for PIA

- Native Gluetun support with automatic server selection
- Simple username/password authentication (no token generation)
- Automatic port forwarding support
- No manual configuration needed

## Configuration Steps

### 1. Create PIA Secret

```bash
# Delete old AirVPN secret
kubectl delete secret gluetun-vpn-secret -n gluetun

# Create PIA secret for OpenVPN (RECOMMENDED)
kubectl create secret generic gluetun-vpn-secret -n gluetun \
  --from-literal=VPN_SERVICE_PROVIDER=private-internet-access \
  --from-literal=VPN_TYPE=openvpn \
  --from-literal=OPENVPN_USER='your-pia-username' \
  --from-literal=OPENVPN_PASSWORD='your-pia-password' \
  --from-literal=SERVER_REGIONS='US Chicago'
```

### 2. Update ConfigMap

Update `/kubernetes/apps/gluetun/configmap.yaml`:

```yaml
data:
  # VPN Provider
  VPN_SERVICE_PROVIDER: "private-internet-access"
  
  # VPN Type (OpenVPN recommended - WireGuard needs manual setup)
  VPN_TYPE: "openvpn"
  
  # Optional: Enable port forwarding for torrenting
  VPN_PORT_FORWARDING: "on"
  VPN_PORT_FORWARDING_PROVIDER: "private-internet-access"
```

### 3. Server Regions (Optional)

PIA supports these regions for `SERVER_REGIONS`:
- US: `US Chicago`, `US East`, `US West`, `US Texas`, `US Florida`, etc.
- International: `UK London`, `Netherlands`, `Switzerland`, etc.
- Full list: https://github.com/qdm12/gluetun/wiki/Private-Internet-Access

### 4. For WireGuard (NOT RECOMMENDED - Complex Setup)

```bash
kubectl create secret generic gluetun-vpn-secret -n gluetun \
  --from-literal=VPN_SERVICE_PROVIDER=private-internet-access \
  --from-literal=VPN_TYPE=openvpn \
  --from-literal=OPENVPN_USER='your-pia-username' \
  --from-literal=OPENVPN_PASSWORD='your-pia-password' \
  --from-literal=SERVER_REGIONS='US Chicago'
```

## Benefits Over AirVPN

1. **Automatic Configuration**: No need to manually manage WireGuard keys
2. **Server Flexibility**: Can specify regions, Gluetun handles the rest
3. **Better Integration**: PIA is one of the most tested providers
4. **Port Forwarding**: Automatic support for torrenting

## Verification

After setup:
```bash
# Restart Gluetun
kubectl rollout restart deployment gluetun -n gluetun

# Check logs
kubectl logs -n gluetun deployment/gluetun -f

# Should see:
# "VPN is up and running"
# "Public IP address is x.x.x.x"
```