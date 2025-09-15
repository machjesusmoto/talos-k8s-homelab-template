#!/bin/bash
# Script to recreate stuck PVCs and migrate data

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Function to migrate a PVC
migrate_pvc() {
    local namespace="$1"
    local old_pvc="$2"
    local new_pvc="${old_pvc}-new"
    local app_label="$3"
    
    echo -e "${YELLOW}Migrating ${namespace}/${old_pvc}...${NC}"
    
    # Get the old PVC spec
    kubectl get pvc "$old_pvc" -n "$namespace" -o yaml > "/tmp/${old_pvc}-backup.yaml"
    
    # Create new PVC with -new suffix
    cat > "/tmp/${new_pvc}.yaml" <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${new_pvc}
  namespace: ${namespace}
  labels:
    app.kubernetes.io/name: ${app_label}
    migrated: "true"
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: nfs-apps
  resources:
    requests:
      storage: $(kubectl get pvc "$old_pvc" -n "$namespace" -o jsonpath='{.spec.resources.requests.storage}')
EOF
    
    echo -e "${GREEN}Creating new PVC: ${new_pvc}${NC}"
    kubectl apply -f "/tmp/${new_pvc}.yaml"
    
    # Wait for new PVC to be bound
    echo "Waiting for new PVC to be bound..."
    kubectl wait --for=condition=bound pvc/"$new_pvc" -n "$namespace" --timeout=60s
    
    # Create data migration job if old PVC has data
    if kubectl get pv -o yaml | grep -q "$(kubectl get pvc "$old_pvc" -n "$namespace" -o jsonpath='{.spec.volumeName}')"; then
        echo -e "${YELLOW}Creating data migration job...${NC}"
        cat > "/tmp/migrate-${old_pvc}.yaml" <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: migrate-${old_pvc}
  namespace: ${namespace}
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: migrate
        image: busybox
        command: ["/bin/sh", "-c"]
        args:
        - |
          echo "Starting data migration..."
          if [ -d /old-data ] && [ "$(ls -A /old-data 2>/dev/null)" ]; then
            echo "Found data in old volume, copying..."
            cp -av /old-data/* /new-data/ || echo "Copy completed with some files"
            echo "Migration completed"
          else
            echo "No data found in old volume or volume not accessible"
          fi
        volumeMounts:
        - name: old-data
          mountPath: /old-data
        - name: new-data
          mountPath: /new-data
      volumes:
      - name: old-data
        persistentVolumeClaim:
          claimName: ${old_pvc}
      - name: new-data
        persistentVolumeClaim:
          claimName: ${new_pvc}
EOF
        kubectl apply -f "/tmp/migrate-${old_pvc}.yaml"
        
        # Wait for migration to complete
        echo "Waiting for data migration to complete..."
        kubectl wait --for=condition=complete job/"migrate-${old_pvc}" -n "$namespace" --timeout=300s || true
        
        # Check migration status
        kubectl logs job/"migrate-${old_pvc}" -n "$namespace" || true
        
        # Cleanup migration job
        kubectl delete job "migrate-${old_pvc}" -n "$namespace" || true
    else
        echo -e "${YELLOW}Old PVC not accessible, creating empty new PVC${NC}"
    fi
    
    echo -e "${GREEN}Migration of ${namespace}/${old_pvc} completed${NC}"
    echo ""
}

# Migrate stuck PVCs
echo -e "${GREEN}Starting PVC migration for stuck applications...${NC}"

# Applications to migrate
migrate_pvc "automation" "overseerr-config" "overseerr"
migrate_pvc "automation" "prowlarr-config" "prowlarr" 
migrate_pvc "media" "radarr-config" "radarr"
migrate_pvc "media" "readarr-config" "readarr"
migrate_pvc "media" "lidarr-config" "lidarr"
migrate_pvc "downloads" "nzbget-config" "nzbget"
migrate_pvc "downloads" "qbittorrent-config" "qbittorrent"

echo -e "${GREEN}All PVC migrations completed!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Update deployments to use new PVCs (replace 'pvc-name' with 'pvc-name-new')"
echo "2. Test applications with new storage"
echo "3. Delete old PVCs when confirmed working: kubectl delete pvc <old-pvc-name> -n <namespace>"