#!/usr/bin/env bash
set -euo pipefail

POD=$(kubectl get pods -l app=vikunja -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod "$POD"
kubectl logs "$POD" -c api --tail=200
