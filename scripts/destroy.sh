#!/usr/bin/env bash
set -euo pipefail

ENV=${1:-dev}

echo "[Destroy] Removing Helm release"
helm uninstall vikunja || true

echo "[Destroy] Terraform destroy"
terraform destroy -auto-approve -var-file="environments/${ENV}.tfvars"
