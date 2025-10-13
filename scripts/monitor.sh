#!/usr/bin/env bash
set -euo pipefail

echo "[Monitor] Top pods"
kubectl top pods --all-namespaces || echo "metrics-server not installed"

echo "[Monitor] Recent events"
kubectl get events --sort-by=.metadata.creationTimestamp | tail -n 20

echo "[Monitor] HPA status"
kubectl get hpa

echo "[Monitor] Pods status"
kubectl get pods -o wide
