# Vikunja on GKE (Terraform + Helm)

Minimal, production‑leaning deployment of Vikunja on Google Kubernetes Engine using Terraform (infra) and Helm (app). Optional components: Cloud SQL (Postgres), Keycloak for OIDC, Google Managed Certificate TLS, and GitHub Actions CI/CD.

---

## 1. What You Get
* GKE cluster + networking (Terraform)
* (Optional) Cloud SQL Postgres or self‑hosted Postgres manifest
* Helm charts: `vikunja` (API + frontend), `platform` (shared ingress), optional `keycloak`
* Shared GCE Ingress with static global IP + (optional) managed TLS cert
* OIDC wiring (Vikunja ↔ Keycloak) via environment variables

## 2. Quick Start (Dev)
Prereqs: gcloud, terraform >= 1.6, helm, authenticated to a GCP project.

```bash
PROJECT_ID="your-project"
REGION="europe-west1" # adjust
gsutil mb -p "$PROJECT_ID" -l $REGION gs://$PROJECT_ID-tf-state || true
gsutil versioning set on gs://$PROJECT_ID-tf-state

terraform init \
  -backend-config="bucket=$PROJECT_ID-tf-state" \
  -backend-config="prefix=terraform"

terraform workspace new dev 2>/dev/null || true
terraform workspace select dev
export TF_VAR_db_password="$(openssl rand -base64 20)"
terraform apply -var-file=environments/dev.tfvars -auto-approve

gcloud container clusters get-credentials $(terraform output -raw gke_cluster_name) --region $(terraform output -raw region)
helm upgrade --install vikunja charts/vikunja \
  --set cloudsql.instanceConnectionName="$(terraform output -raw cloudsql_instance)" \
  --set postgres.host=127.0.0.1
```

Open (if DNS not configured):
```bash
kubectl port-forward svc/vikunja 8080:80
open http://localhost:8080
```

## 3. Configuration Overview
| Area | How |
|------|-----|
| DB | Cloud SQL (default) or self-hosted StatefulSet (`scripts/k8s/`). |
| Auth (OIDC) | Keycloak realm `vikunja`; env vars `VIKUNJA_AUTH_OPENID_*`. |
| Ingress | Single GCE ingress in `charts/platform`; host rules for Vikunja + Keycloak. |
| TLS | Google Managed Certificate (add domain list to platform values). |
| Scaling | HPA + resource requests/limits. |
| Secrets | Plain k8s Secret now; recommend External Secrets (future). |

## 4. Key Helm Values (Vikunja)
```yaml
openid:
  enabled: true
  issuer: https://keycloak.example.com/realms/vikunja
  clientId: vikunja-web
  redirectURL: https://vikunja.example.com/auth/openid/callback
  confidentialClient: false
```
`VIKUNJA_SERVICE_PUBLICURL` is built from `ingress.host` (even though ingress is centralised). Keep it aligned with the external hostname.

## 5. Enabling Keycloak (Optional)
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade --install keycloak bitnami/keycloak -f scripts/keycloak-values.yaml
```
Then set Vikunja values (or `--set`) for issuer + redirectURL. In Keycloak client `vikunja-web` add redirect URI:
```
https://vikunja.example.com/auth/openid/callback
```
And Web Origin: `https://vikunja.example.com`.

## 6. Domains & TLS
1. Reserve/identify a static global IP (Ingress annotation or pre-created).
2. Create A records:
```
vikunja.example.com  A  <STATIC_IP>
keycloak.example.com A  <STATIC_IP>
```
3. Add ManagedCertificate manifest (or use `charts/platform` value) listing both domains.
4. Wait for status: `kubectl describe managedcertificate <name>` → ACTIVE.

### Using Terraform-Managed Static IP
This repo now provisions a global static IP via Terraform (`google_compute_global_address.platform_lb`).

After `terraform apply`:
```bash
terraform output platform_lb_ip_address
terraform output platform_lb_ip_name
```
Set the Helm value (already defaults correctly) or override:
```bash
helm upgrade --install platform charts/platform \
  --set staticIpName=$(terraform output -raw platform_lb_ip_name)
```
Point DNS A records to the `platform_lb_ip_address` value.

## 7. CI/CD (GitHub Actions)
Secrets typically required:
* GCP_PROJECT_ID
* GCP_REGION
* GCP_WIF_PROVIDER (Workload Identity provider resource name)
* GCP_TERRAFORM_SA (service account email)
* TF_STATE_BUCKET

Workflow flow:
* PR → terraform plan (dev workspace) + helm lint
* Merge to main → terraform apply (prod workspace) + helm upgrade

## 8. Rollbacks
* App: `helm rollback vikunja <rev>`
* Infra: revert commit → `terraform apply`

## 9. Self‑Hosted Postgres (Alternative)
Disable Cloud SQL in tfvars (`enable_cloudsql=false`), apply Postgres manifest, then:
```bash
helm upgrade --install vikunja charts/vikunja \
  --set cloudsql.enabled=false \
  --set postgres.host=postgres.default.svc.cluster.local
```

## 10. Troubleshooting OIDC
* Check env: `kubectl exec deploy/vikunja -c api -- printenv | grep VIKUNJA_AUTH_OPENID`
* Discovery URL: `curl https://keycloak.example.com/realms/vikunja/.well-known/openid-configuration`
* If providers list is empty in `/api/v1/info`: ensure redirectURL matches Keycloak client redirect exactly and restart deployment.

## 11. Hardening (Next Steps)
Short list of recommended follow-ups:
* External Secrets + Secret Manager for DB & OIDC secrets
* Private Cloud SQL + Cloud SQL Auth Proxy sidecar
* Fine-grained IAM instead of broad roles
* NetworkPolicy (restrict egress to DB + Keycloak + DNS)
* Prometheus/Grafana stack & alerting
* Automated Keycloak realm bootstrap job

## 12. Clean Up
```bash
terraform workspace select dev
terraform destroy -var-file=environments/dev.tfvars -auto-approve
```

## 13. Disclaimer
Sample values are not production-ready. Replace demo passwords, enable managed secrets, and review security posture before real-world use.
