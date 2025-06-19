# Core Infrastructure Deployment

This directory contains the core infrastructure components needed for the cluster.

## Components

1. **NFS CSI Driver** - For mounting TrueNAS NFS shares
2. **MetalLB** - For LoadBalancer service types
3. **Ingress Controller** - For HTTP/HTTPS routing
4. **cert-manager** - For automatic TLS certificates

## Deployment Order

```bash
# 1. Create namespaces
kubectl apply -f namespaces/

# 2. Deploy NFS CSI Driver
kubectl apply -k nfs-csi/

# 3. Deploy MetalLB
kubectl apply -k metallb/

# 4. Deploy Ingress
kubectl apply -k ingress-nginx/

# 5. Deploy cert-manager
kubectl apply -k cert-manager/
```

Or deploy everything at once:
```bash
kubectl apply -k .
```
