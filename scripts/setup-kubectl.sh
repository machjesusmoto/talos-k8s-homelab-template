#!/bin/bash

CLUSTER=$1

if [[ -z "$CLUSTER" ]]; then
  echo "Usage: $0 <cluster>"
  echo "Clusters: dev, test, prod"
  exit 1
fi

case $CLUSTER in
  dev)
    MASTER_IP="192.168.1.244"
    CONFIG_NAME="config-dev"
    ;;
  test)
    MASTER_IP="192.168.1.251"
    CONFIG_NAME="config-test"
    ;;
  prod)
    MASTER_IP="192.168.1.241"
    CONFIG_NAME="config-prod"
    ;;
  *)
    echo "Unknown cluster: $CLUSTER"
    exit 1
    ;;
esac

echo "Setting up kubectl for $CLUSTER cluster..."

# Create .kube directory if it doesn't exist
mkdir -p ~/.kube

# Copy kubeconfig from master
echo "Copying kubeconfig from $MASTER_IP..."
scp dtaylor@${MASTER_IP}:/etc/rancher/k3s/k3s.yaml ~/.kube/${CONFIG_NAME}

# Update server address
sed -i "s/127.0.0.1/${MASTER_IP}/g" ~/.kube/${CONFIG_NAME}

# Set KUBECONFIG
export KUBECONFIG=~/.kube/${CONFIG_NAME}
echo "export KUBECONFIG=~/.kube/${CONFIG_NAME}" >> ~/.bashrc

# Test connection
echo "Testing connection..."
kubectl get nodes

echo "kubectl configured for $CLUSTER cluster!"
echo "To use: export KUBECONFIG=~/.kube/${CONFIG_NAME}"
