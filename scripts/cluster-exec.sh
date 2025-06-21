#!/bin/bash
# Execute commands across Talos cluster nodes - Linux version
# Usage: ./cluster-exec.sh <target> "command to run"

TARGET=$1
COMMAND=$2

if [[ -z "$TARGET" || -z "$COMMAND" ]]; then
  echo "Usage: $0 <target> \"<command>\""
  echo "Targets: cp|controlplane, workers, all"
  echo ""
  echo "Examples:"
  echo "  $0 cp \"uptime\""
  echo "  $0 workers \"df -h\""
  echo "  $0 all \"free -h\""
  exit 1
fi

# Node definitions
CONTROL_PLANES=("192.168.1.241" "192.168.1.242" "192.168.1.243")
WORKERS=("192.168.1.244" "192.168.1.245")

# Determine target nodes
case $TARGET in
  cp|controlplane)
    TARGET_NODES=("${CONTROL_PLANES[@]}")
    TARGET_NAME="Control Plane"
    ;;
  workers)
    TARGET_NODES=("${WORKERS[@]}")
    TARGET_NAME="Worker"
    ;;
  all)
    TARGET_NODES=("${CONTROL_PLANES[@]}" "${WORKERS[@]}")
    TARGET_NAME="All"
    ;;
  *)
    echo "Unknown target: $TARGET"
    echo "Valid targets: cp|controlplane, workers, all"
    exit 1
    ;;
esac

echo "=== Executing command on $TARGET_NAME nodes ==="
echo "Command: $COMMAND"
echo "Nodes: ${TARGET_NODES[*]}"
echo ""

success_count=0
fail_count=0

for node in "${TARGET_NODES[@]}"; do
  echo "=== Node: $node ==="
  
  # Execute command via talosctl
  if talosctl exec --nodes "$node" -- $COMMAND; then
    ((success_count++))
  else
    echo "Command failed on $node"
    ((fail_count++))
  fi
  
  echo ""
done

# Summary
echo "=== Execution Summary ==="
echo "Successful: $success_count"
echo "Failed: $fail_count"
echo "Total nodes: ${#TARGET_NODES[@]}"

if [[ $fail_count -gt 0 ]]; then
    echo ""
    echo "Some commands failed. Check the output above for details."
    exit 1
fi
