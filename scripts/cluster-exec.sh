#!/bin/bash
# Usage: ./cluster-exec.sh <cluster> "command to run"

CLUSTER=$1
COMMAND=$2

if [[ -z "$CLUSTER" || -z "$COMMAND" ]]; then
  echo "Usage: $0 <cluster> <command>"
  echo "Clusters: dev, test, prod, all"
  exit 1
fi

case $CLUSTER in
  dev)
    HOSTS="docker-dev-01 docker-dev-02 docker-dev-03"
    ;;
  test)
    HOSTS="docker-test-01 docker-test-02 docker-test-03"
    ;;
  prod)
    HOSTS="docker-prod-01 docker-prod-02 docker-prod-03"
    ;;
  all)
    HOSTS="docker-dev-01 docker-dev-02 docker-dev-03 docker-test-01 docker-test-02 docker-test-03 docker-prod-01 docker-prod-02 docker-prod-03"
    ;;
  *)
    echo "Unknown cluster: $CLUSTER"
    exit 1
    ;;
esac

for host in $HOSTS; do
  echo -e "\n=== $host ==="
  ssh dtaylor@${host} "$COMMAND"
done
