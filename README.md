# Vikunja on GKE

Fully automated deployment of Vikunja (API + frontend) on Google Kubernetes Engine using Terraform for infrastructure and Helm for applications. Includes optional Keycloak for OIDC and private Cloud SQL Postgres. A shared GCE Ingress exposes both services over a single global static IP.

## Table of Contents
1. Overview
2. Architecture Diagram (Conceptual)
3. Quick Start (Dev)
4. Infrastructure Modules
5. Helm Charts & Configuration
6. Secrets & Security Model
7. OIDC / Keycloak Integration
8. CI/CD Workflow
9. Operations (Scale, Rollback, Cleanup)
10. Hardening & Production Notes

## 1. Overview
Provisioned components:
- VPC + Subnet + secondary ranges (Pods / Services)
- Private Service Networking for Cloud SQL
- GKE cluster (Workload Identity enabled)
- Optional private-only Cloud SQL instance (Vikunja + optional Keycloak DBs)
- Global static IPv4 + shared ingress (`charts/platform`)
- Helm charts: `vikunja`, `keycloak`, `platform`

## 2. Architecture (Conceptual)
```
   Internet
      |
  Global Static IP (GCE Ingress)  <-- ManagedCertificate (HTTPS)
      |
  +----------------------------+
  |          Ingress          |
  +--------------+------------+
                 |
        +--------+--------+
        |                 |
    Vikunja Service   Keycloak Service
        |                 |
   (API+Frontend Pods)   (Keycloak Pod)
        |
   Cloud SQL (Private IP)
```

## 3. Quick Start (Dev Environment)
Prerequisites: `terraform >= 1.6`, `gcloud`, `helm`, `openssl`.
```bash
PROJECT_ID="your-project"
REGION="us-central1"
gsutil mb -p "$PROJECT_ID" -l $REGION gs://$PROJECT_ID-tf-state || true
terraform init -backend-config="bucket=$PROJECT_ID-tf-state" -backend-config="prefix=terraform"
terraform workspace new dev 2>/dev/null || true
terraform workspace select dev
export TF_VAR_vikunja_db_password="$(openssl rand -base64 32)"
export TF_VAR_keycloak_db_password="$(openssl rand -base64 32)"
terraform apply -var-file=environments/dev.tfvars -auto-approve

gcloud container clusters get-credentials $(terraform output -raw gke_cluster_name) --region $REGION
# Create application secrets
kubectl create secret generic vikunja-db --from-literal=password="$TF_VAR_vikunja_db_password" --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic vikunja-oidc-client --from-literal=clientsecret="CHANGE_ME" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install vikunja charts/vikunja \
  --set cloudsql.instanceConnectionName="$(terraform output -raw cloudsql_instance)" \
  --set postgres.host=127.0.0.1
```
If DNS/Ingress not ready, port‑forward:
```bash
kubectl port-forward svc/vikunja 8080:80
open http://localhost:8080
```

## 4. Infrastructure Modules
| Module | Purpose |
|--------|---------|
| `network` | VPC, subnet, secondary ranges, private service networking peering |
| `gke` | GKE cluster + node pool (autoscaling, workload identity, monitoring) |
| `cloudsql` | Postgres instance, databases & users (private IP only) |

Key design: private Cloud SQL via service networking (`google_service_networking_connection`). Public IP disabled.

## 5. Helm Charts & Configuration
`charts/vikunja`:
- Deployment (API + frontend containers)
- ConfigMap (`config.yml`) with OpenID provider list
- Secret-based OIDC client secret injected via env var
- HPA (conditional on `autoscaling.enabled`)
- Service exposing ports 80 (frontend) & 3456 (API)

Important values (`charts/vikunja/values.yaml`):
| Key | Purpose |
|-----|---------|
| `postgres.secretName` | Kubernetes Secret containing DB password |
| `openid.providers[]` | List of OIDC providers (name, authurl, logouturl, clientid, scopes) |
| `openid.secretName` | Secret containing confidential client secret |
| `autoscaling.*` | HPA configuration (enabled, min/max, targetCPUUtilizationPercentage) |
| `resources.*` | API container resource requests/limits |

## 6. Secrets & Security Model
Secrets are delivered via Kubernetes Secrets (not ConfigMaps):
- `vikunja-db`: Postgres password (`VIKUNJA_DATABASE_PASSWORD` via secretKeyRef)
- `vikunja-oidc-client`: OIDC client confidential secret (`VIKUNJA_AUTH_OPENID_PROVIDERS_0_CLIENTSECRET`)

Recommended hardening:
- Use GCP Secret Manager + External Secrets Operator (future)
- Enable NetworkPolicies to restrict egress
- Add PodSecurity / runAsNonRoot settings
- Rotate secrets via CI and rolling restart

## 7. OIDC / Keycloak Integration
Chart now uses provider array only:
```yaml
openid:
  enabled: true
  secretName: vikunja-oidc-client
  providers:
    - name: keycloak
      authurl: https://keycloak.misskecupbung.xyz/realms/vikunja/protocol/openid-connect/auth
      logouturl: https://keycloak.misskecupbung.xyz/realms/vikunja/protocol/openid-connect/logout
      clientid: vikunja
      scopes: [openid, email, profile]
```
Redirect URL pattern inside Vikunja: `https://<host>/auth/openid/<provider-name>`.

Debug commands:
```bash
kubectl logs deploy/vikunja -c api | grep -i openid || true
curl -s https://keycloak.misskecupbung.xyz/realms/vikunja/.well-known/openid-configuration | jq '.issuer'
```
Add another provider by appending to `openid.providers` and providing its secret (if confidential).

## 8. CI/CD Workflow
GitHub Actions pipeline stages:
1. Plan: Terraform plan + Helm lint + kubeconform.
2. Apply: Terraform apply (infra creation/update).
3. Deploy Keycloak: Helm upgrade with realm settings.
4. Deploy Vikunja: Creates secrets, deploys chart.
5. Deploy Platform ingress: Shared static IP + hostname routing.

## 9. Operations
Scale manually (if HPA disabled):
```bash
kubectl scale deploy/vikunja --replicas=3
```
Rollback:
```bash
helm rollback vikunja <revision>
```
Restart:
```bash
kubectl rollout restart deploy/vikunja
```
Cleanup:
```bash
terraform workspace select dev
terraform destroy -var-file=environments/dev.tfvars -auto-approve
```

## 10. Hardening & Production Notes
- Cloud SQL tier: increase from `db-f1-micro` to production class (e.g., `db-custom-2-8192`).
- Set `autoscaling.maxReplicas` per load tests.
- Add Prometheus metrics & alerts.
- Enforce NetworkPolicy deny-all + explicit allowlist.
- TLS termination: ensure certificate covers all hostnames.
- Regular backups verified & PITR expectations documented.

## Troubleshooting Cheat Sheet
| Issue | Likely Cause | Action |
|-------|--------------|--------|
| 403 after OIDC redirect | Redirect URI mismatch | Verify provider name & Keycloak client redirect URIs |
| OIDC providers missing | Empty providers list or parse error | Check ConfigMap render & pod logs |
| DB auth failures | Secret name/key mismatch | Confirm `vikunja-db` secret and env var mapping |
| Slow startup probes fail | Probe timing too aggressive | Increase `initialDelaySeconds` or `periodSeconds` |
| Missing HPA | `autoscaling.enabled` false | Set value or add to `values.yaml` |

---
Defaults target development convenience. Review secrets, network policy, storage class, and resource sizing before production use.