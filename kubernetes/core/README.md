# Core Infrastructure Deployment

This directory contains the core infrastructure components needed for the cluster.

## Components

1. **kube-proxy** - Required for service routing in Talos Linux
2. **NFS CSI Driver** - For mounting TrueNAS NFS shares
3. **MetalLB** - For LoadBalancer service types
4. **Ingress Controller** - For HTTP/HTTPS routing
5. **cert-manager** - For automatic TLS certificates

## Important Note for Talos Linux

When using Talos with `proxy.disabled: true` in the configuration, kube-proxy must be deployed manually to ensure proper service routing. Without it, pods cannot reach the Kubernetes API or other services via ClusterIP.

## Deployment Order

```bash
# 1. Create namespaces
kubectl apply -f namespaces/

# 2. Deploy kube-proxy (CRITICAL for Talos)
kubectl apply -k kube-proxy/

# 3. Deploy NFS CSI Driver
kubectl apply -k nfs-csi/

# 4. Deploy MetalLB
kubectl apply -k metallb/

# 5. Deploy Ingress
kubectl apply -k ingress-nginx/

# 6. Deploy cert-manager
kubectl apply -k cert-manager/
```

Or deploy everything at once:
```bash
kubectl apply -k .
```
