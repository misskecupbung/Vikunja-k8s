<<<<<<< HEAD
<<<<<<< HEAD
# Currently i’m still cooking the dishes.
=======
# Vikunja Kubernetes & GKE Terraform Deployment
=======
# Vikunja on GKE (Terraform + Helm)
>>>>>>> cb86d2f (add files)

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

<<<<<<< HEAD
To deploy prod locally:
```
terraform workspace select prod
terraform apply -var-file=environments/prod.tfvars -auto-approve
```

### 4. Trigger GitHub Actions (Workspace Aware)
* Pull Requests: workflow selects `dev` workspace and runs plan with `environments/dev.tfvars`.
* Push to `main`: workflow selects (or creates) `prod` workspace and applies with `environments/prod.tfvars`.

### 5. Rollback Strategy
* Helm: `helm rollback vikunja <rev>`
* Terraform: use previous commit + `terraform apply` (state is versioned in GCS)

### 6. Security Hardening (Follow-up)
* Replace Owner role with granular roles: `roles/container.admin`, `roles/compute.networkAdmin`, `roles/cloudsql.admin`, `roles/iam.serviceAccountUser`.
* Use Secret Manager + External Secrets for DB password.
* Enable CMEK for Cloud SQL disks.
* Add binary authorization / admission controls.

Port-forward locally (if no DNS):

```
kubectl port-forward svc/vikunja 8080:80
```

## Destroy

```
./scripts/destroy.sh dev
```

## Local Self-Hosted Postgres Option

Instead of Cloud SQL: disable in tfvars `enable_cloudsql=false`, deploy the included manifest:

```
kubectl apply -f scripts/k8s/database-statefulset.yaml
helm upgrade --install vikunja charts/vikunja \
	--set cloudsql.enabled=false \
	--set postgres.host=postgres.default.svc.cluster.local
```

## Monitoring & Troubleshooting

* `scripts/monitor.sh` for quick cluster workload view.
* Integrate GKE native Cloud Logging & Cloud Monitoring (already enabled in cluster settings).
* Add Prometheus stack (future enhancement) for application metrics; expose Vikunja metrics endpoint (if available) or sidecar exporter.
* `scripts/debug.sh` gathers describe + logs for first Vikunja pod.

## External Secrets Integration (Optional)
## OIDC Integration (Keycloak + Vikunja)

This repository now configures a Keycloak realm `vikunja` with a public client `vikunja-web` and enables OpenID Connect in the Vikunja deployment automatically via the GitHub Actions workflow.

### Flow Summary
1. Keycloak deploy step provisions the realm and client (Helm post-install Job).
2. Vikunja deploy step sets `VIKUNJA_AUTH_OPENID_*` env vars (issuer, client id, redirect URL) via Helm values.
3. Shared `platform` ingress exposes both hosts on a single static IP.

### Required DNS
Point your chosen domains (examples below) to the static IP allocated for the GCE ingress:

```
vikunja.example.com   A   <STATIC_IP>
auth.example.com      A   <STATIC_IP>
```

Then set these environment overrides in the workflow (or via `--set` locally):

```
KEYCLOAK_HOST=auth.example.com
VIKUNJA_HOST=vikunja.example.com
```

The workflow already passes updated redirect URIs and issuer values to both charts. If using TLS (recommended), install cert-manager and add a `tls:` block to the platform ingress chart.

### Testing Login
1. Browse to `https://vikunja.example.com/` and click login.
2. You should be redirected to Keycloak at `https://auth.example.com/realms/vikunja/...`.
3. Authenticate with a Keycloak user (create one via Keycloak admin console at `/admin` if needed).
4. You are returned to Vikunja with an authenticated session.

### Switching to Confidential Client (Optional)
If you prefer a confidential client:
1. Set `openid.confidentialClient=true` in Vikunja values.
2. Create a secret containing `CLIENT_SECRET` and pass `--set openid.secretName=<secret>`.
3. Adjust Keycloak client to `publicClient=false` and add the generated secret.

The bootstrap job currently creates only a public client; extend `realm.clients` with a new entry if needed and redeploy.


This chart can leverage the External Secrets Operator to source the database password from a secret manager (e.g., Google Secret Manager).

1. Install operator (example):
```
helm repo add external-secrets https://charts.external-secrets.io
helm upgrade --install external-secrets external-secrets/external-secrets \
	--set installCRDs=true
```
2. Configure a `SecretStore` referencing GCP Workload Identity (example):
```
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
	name: gcp-secretstore
spec:
	provider:
		gcpsm:
			projectID: ${PROJECT_ID}
```
3. Create secret in GCP (if using GSM):
```
echo -n 'ChangeMe123!' | gcloud secrets create vikunja-db-password --data-file=-
```
4. Enable in Helm values (and omit TF_VAR_db_password if Cloud SQL password is only needed inside DB provisioning flow—alternatively let Cloud SQL create a random user and manage separately):
```
externalSecrets:
	enabled: true
	externalSecrets:
		secretName: vikunja-db-credentials
```
5. Deploy/upgrade chart. The plain Secret manifest is skipped when external secrets are enabled.

CI validates rendered manifests with `helm template` + `kubeconform`.

### Handling Database Password Securely

The variable `db_password` has no default and is intentionally omitted from tfvars files. Supply it by one of these methods:
1. Environment variable before terraform commands:
	`export TF_VAR_db_password=$(gcloud secrets versions access latest --secret=vikunja-db-password)`
2. GitHub Actions secret: add `TF_VAR_db_password` in repo secrets (only for dev/testing; prefer GSM + External Secrets in prod).
3. Rotate by updating the secret and re-running `terraform apply` (will force user password update in Cloud SQL).
4. For self-hosted Postgres, you can override Helm values using External Secrets so the password never appears in state (Cloud SQL user password still lands in state unless using a generated random + ignore_changes pattern—future enhancement).

Makefile targets ease local workflows (`make init plan apply helm-template`).

### Workspace Notes
* State objects share the same bucket/prefix; Terraform appends `env:<workspace>` internally.
* Switch environments safely with `terraform workspace select <name>` before planning/applying.
* Use a label or `locals { env = terraform.workspace }` pattern to tag resources if needed.

## Further Enhancements (Future Work)

* Add Terraform module for separate node pools (spot vs. on-demand).
* Implement External Secrets + Secret Manager integration.
* Add CI pipeline (GitHub Actions) for terraform plan + helm lint + kubeval.
* Enable GKE Autopilot evaluation (cost vs. control trade-off).
* Add Keycloak realm & client bootstrap automation (Realm JSON + kcadm script).

## Disclaimer

This is a reference implementation for interview purposes; hard-coded sample values (passwords, hosts) must be replaced with secure secret management and environment-specific overrides before production use.
>>>>>>> c10c5cb (refine egress)
=======
## 13. Disclaimer
Sample values are not production-ready. Replace demo passwords, enable managed secrets, and review security posture before real-world use.
>>>>>>> cb86d2f (add files)
