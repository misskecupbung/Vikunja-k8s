#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="default"
SHOW_LOGS=1
INGRESS_NAME="platform"
WIDE=0

usage() {
  echo "Usage: $0 [-n namespace] [--no-logs] [--ingress name] [--wide]" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--namespace) NAMESPACE="$2"; shift 2 ;;
    --no-logs) SHOW_LOGS=0; shift ;;
    --ingress) INGRESS_NAME="$2"; shift 2 ;;
    --wide) WIDE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

section() { echo -e "\n=== $1 ==="; }

section "Context"
kubectl config current-context || true

section "Nodes"
if [[ $WIDE -eq 1 ]]; then kubectl get nodes -o wide; else kubectl get nodes; fi

section "Pods ($NAMESPACE)"
if [[ $WIDE -eq 1 ]]; then kubectl get pods -n "$NAMESPACE" -o wide; else kubectl get pods -n "$NAMESPACE"; fi

section "Recent Events ($NAMESPACE, last 50)"
kubectl get events -n "$NAMESPACE" --sort-by=.metadata.creationTimestamp | tail -n 50 || true

section "Deployments"
kubectl get deploy -n "$NAMESPACE" || true

section "ReplicaSets (latest 5)"
kubectl get rs -n "$NAMESPACE" --sort-by=.metadata.creationTimestamp | tail -n 5 || true

section "Services"
kubectl get svc -n "$NAMESPACE" || true

section "Ingress List"
kubectl get ingress -n "$NAMESPACE" || true

if kubectl get ingress -n "$NAMESPACE" "$INGRESS_NAME" >/dev/null 2>&1; then
  section "Ingress Describe: $INGRESS_NAME"
  kubectl describe ingress -n "$NAMESPACE" "$INGRESS_NAME" || true
fi

section "HPA"
kubectl get hpa -n "$NAMESPACE" || true

section "Top Pods"
kubectl top pods -n "$NAMESPACE" 2>/dev/null || echo "metrics-server not installed"

if [[ $SHOW_LOGS -eq 1 ]]; then
  section "Logs (last 100 lines) vikunja"
  POD=$(kubectl get pods -n "$NAMESPACE" -l app=vikunja -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
  if [[ -n "$POD" ]]; then
    kubectl logs -n "$NAMESPACE" "$POD" --tail=100 || true
  else
    echo "No vikunja pod found"
  fi
fi

section "Done"
