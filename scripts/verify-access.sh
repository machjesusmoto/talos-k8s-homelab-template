#!/bin/bash

echo "Testing SSH key access and passwordless sudo on all hosts..."

HOSTS=(
  "192.168.1.244"  # docker-dev-01
  "192.168.1.245"  # docker-dev-02
  "192.168.1.246"  # docker-dev-03
  "192.168.1.251"  # docker-test-01
  "192.168.1.252"  # docker-test-02
  "192.168.1.253"  # docker-test-03
  "192.168.1.241"  # docker-prod-01
  "192.168.1.242"  # docker-prod-02
  "192.168.1.243"  # docker-prod-03
)

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

for host in "${HOSTS[@]}"; do
  echo -e "\n=== Testing $host ==="
  
  # Test SSH connection
  echo -n "SSH Connection: "
  if ssh -o BatchMode=yes -o ConnectTimeout=5 dtaylor@$host "echo 'OK'" 2>/dev/null; then
    echo -e "${GREEN}✓ Success${NC}"
  else
    echo -e "${RED}✗ Failed${NC}"
    continue
  fi
  
  # Test sudo without password
  echo -n "Passwordless Sudo: "
  if ssh -o BatchMode=yes dtaylor@$host "sudo whoami" 2>/dev/null | grep -q root; then
    echo -e "${GREEN}✓ Success${NC}"
  else
    echo -e "${RED}✗ Failed${NC}"
  fi
  
  # Get system info
  ssh -o BatchMode=yes dtaylor@$host "
    echo 'Hostname:' \$(hostname)
    echo 'IP:' \$(hostname -I | awk '{print \$1}')
    echo 'Memory:' \$(free -h | grep Mem | awk '{print \$2}')
    echo 'CPU:' \$(nproc) cores
  " 2>/dev/null
done
