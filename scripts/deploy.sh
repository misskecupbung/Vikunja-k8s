#!/usr/bin/env bash
set -euo pipefail

ENV=${1:-dev}
VALUES_FILE=${2:-values-${ENV}.yaml}

echo "[Deploy] Terraform init/apply"
terraform init -upgrade
terraform apply -auto-approve -var-file="environments/${ENV}.tfvars"

echo "[Deploy] Getting credentials"
gcloud container clusters get-credentials "$(terraform output -raw gke_cluster_name)" --region "$(terraform output -raw gke_cluster_name | sed 's/.*/${region:-}/')" || true

echo "[Deploy] Installing/Upgrading Helm release"
helm upgrade --install vikunja charts/vikunja -f "${VALUES_FILE}" \
  --set cloudsql.instanceConnectionName="$(terraform output -raw cloudsql_instance 2>/dev/null || echo '')" || true

echo "[Deploy] Done. Use kubectl get pods to verify."
