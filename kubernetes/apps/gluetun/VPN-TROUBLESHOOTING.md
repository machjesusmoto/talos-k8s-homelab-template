# VPN Troubleshooting Guide for Gluetun

This guide helps troubleshoot common VPN connection issues with Gluetun in Kubernetes.

## Common Issues and Solutions

### 1. VPN Provider Name Errors

**Symptom**: `private-internet-access must be one of private internet access`

**Cause**: Provider names must match exactly, including spaces and capitalization

**Solution**: Use the exact provider name from the Gluetun wiki:
- ❌ `private-internet-access` 
- ✅ `private internet access`
- ❌ `mullvad-vpn`
- ✅ `mullvad`

### 2. Server Region Format Errors

**Symptom**: `us_seattle is not valid`

**Cause**: Server names must match provider's format exactly

**Solution**: Check the correct format for your provider:
- PIA: `US Seattle` (capitalized with space)
- Mullvad: `se-sto` (lowercase with hyphen)
- AirVPN: `netherlands` (lowercase)

### 3. Authentication Failures

**Symptom**: `AUTH: Received control message: AUTH_FAILED`

**Cause**: Incorrect credentials or wrong secret format

**Solution**:
```bash
# Verify secret exists
kubectl get secret -n gluetun

# Check secret contents (base64 decoded)
kubectl get secret vpn-credentials -n gluetun -o jsonpath='{.data.username}' | base64 -d
```

### 4. Certificate Issues (AirVPN)

**Symptom**: `Cannot read inline CA certificate`

**Cause**: Certificates not properly extracted from .ovpn file

**Solution**: Extract certificates from .ovpn file:
```bash
# Extract CA certificate
sed -n '/<ca>/,/<\/ca>/p' airvpn.ovpn | sed '1d;$d' > ca.crt

# Extract client certificate
sed -n '/<cert>/,/<\/cert>/p' airvpn.ovpn | sed '1d;$d' > client.crt

# Extract client key
sed -n '/<key>/,/<\/key>/p' airvpn.ovpn | sed '1d;$d' > client.key
```

### 5. Routing Conflicts

**Symptom**: `OpenVPN tried to add an IP route which already exists`

**Cause**: Network conflicts or stale routes

**Solution**: Restart the Gluetun deployment:
```bash
kubectl rollout restart deployment/gluetun -n gluetun
```

### 6. DNS Resolution Issues

**Symptom**: Cannot resolve hostnames inside VPN

**Cause**: DNS configuration conflicts

**Solution**: Use Gluetun's default DNS settings:
```yaml
env:
- name: DOT
  value: "off"  # Disable DNS over TLS if having issues
```

### 7. Port Forwarding Not Working

**Symptom**: Port forwarding enabled but not active

**Cause**: Provider doesn't support it or wrong configuration

**Solution**: 
- Verify provider supports port forwarding
- Check `VPN_PORT_FORWARDING_PROVIDER` matches `VPN_SERVICE_PROVIDER`
- For PIA: Requires specific regions that support port forwarding

## Debugging Commands

### Check Gluetun Logs
```bash
# Full logs
kubectl logs -n gluetun deployment/gluetun

# Follow logs
kubectl logs -n gluetun deployment/gluetun -f

# Previous container logs (if restarting)
kubectl logs -n gluetun deployment/gluetun --previous
```

### Verify VPN Connection
```bash
# Check if VPN interface exists
kubectl exec -n gluetun deployment/gluetun -- ip addr show tun0

# Check public IP
kubectl exec -n gluetun deployment/gluetun -- wget -qO- http://ipinfo.io/ip

# Check routing table
kubectl exec -n gluetun deployment/gluetun -- ip route
```

### Test Proxy Connectivity
```bash
# Test HTTP proxy
kubectl run test-proxy --rm -it --image=curlimages/curl -- \
  curl -x http://gluetun.gluetun.svc.cluster.local:8888 http://ipinfo.io/ip

# Test SOCKS5 proxy
kubectl run test-socks --rm -it --image=curlimages/curl -- \
  curl --socks5 gluetun.gluetun.svc.cluster.local:1080 http://ipinfo.io/ip
```

## Provider-Specific Configuration

### Private Internet Access (PIA)
```yaml
env:
- name: VPN_SERVICE_PROVIDER
  value: "private internet access"  # Note the spaces!
- name: VPN_TYPE
  value: "openvpn"  # WireGuard requires manual token generation
- name: SERVER_REGIONS
  value: "US Seattle"  # Capitalized with space
```

### AirVPN
```yaml
env:
- name: VPN_SERVICE_PROVIDER
  value: "airvpn"
- name: VPN_TYPE
  value: "wireguard"  # or openvpn
- name: SERVER_COUNTRIES
  value: "netherlands"  # Lowercase
- name: FIREWALL
  value: "off"  # May need to disable for WireGuard
```

For AirVPN OpenVPN configuration:
1. Download .ovpn file from AirVPN config generator
2. Extract certificates and create secret as shown in vpn-secret-template.yaml

### Mullvad
```yaml
env:
- name: VPN_SERVICE_PROVIDER
  value: "mullvad"
- name: VPN_TYPE
  value: "wireguard"
- name: WIREGUARD_PRIVATE_KEY
  valueFrom:
    secretKeyRef:
      name: vpn-credentials
      key: WIREGUARD_PRIVATE_KEY
```

## Health Check Configuration

If Gluetun keeps restarting:

```yaml
# Increase health check delays
env:
- name: HEALTH_VPN_DURATION_INITIAL
  value: "30s"  # Default: 6s
- name: HEALTH_VPN_DURATION_ADDITION
  value: "10s"  # Default: 5s
```

## Complete Reset Procedure

If nothing else works:

1. Delete the Gluetun deployment:
   ```bash
   kubectl delete deployment gluetun -n gluetun
   ```

2. Delete the PVC (if using persistent storage):
   ```bash
   kubectl delete pvc gluetun-data -n gluetun
   ```

3. Verify secret is correct:
   ```bash
   kubectl describe secret vpn-credentials -n gluetun
   ```

4. Redeploy with minimal configuration first
5. Add features incrementally once basic VPN works

## Useful Resources

- [Gluetun Wiki](https://github.com/qdm12/gluetun/wiki)
- [Provider Configurations](https://github.com/qdm12/gluetun/wiki/Provider-configs)
- [Environment Variables](https://github.com/qdm12/gluetun/wiki/Environment-variables)