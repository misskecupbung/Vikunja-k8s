<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
# Currently i’m still cooking the dishes.
=======
# Vikunja Kubernetes & GKE Terraform Deployment
=======
# Vikunja on GKE (Terraform + Helm)
>>>>>>> cb86d2f (add files)
=======
# Vikunja on GKE
>>>>>>> b32fde8 (change cloud aql proxy)

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

<<<<<<< HEAD
<<<<<<< HEAD
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
<<<<<<< HEAD
Sample values are not production-ready. Replace demo passwords, enable managed secrets, and review security posture before real-world use.
<<<<<<< HEAD
>>>>>>> cb86d2f (add files)
=======

>>>>>>> e5a7dd4 (change cloud aql proxy)
=======
Sample values are not production-ready. Replace demo passwords, enable managed secrets, and review security posture before real-world use.
>>>>>>> b0ef09f (change cloud aql proxy)
=======
## Hardening Ideas
- External Secrets + Secret Manager
- Private Cloud SQL (disable public IP)
- NetworkPolicy restrictions
- Observability (Prometheus/Grafana) & alerts
- Automated Keycloak realm bootstrap

## Disclaimer
<<<<<<< HEAD
Defaults are for development. Review security (passwords, network access, TLS) before production use.
>>>>>>> b32fde8 (change cloud aql proxy)
=======
## OpenID Connect (OIDC) Setup & Troubleshooting

### Required Vikunja Values (Keycloak example)
```
openid:
  enabled: true
  issuer: https://keycloak.misskecupbung.xyz/realms/vikunja
  clientId: vikunja-web
  redirectURL: https://vikunja.misskecupbung.xyz/auth/openid/keycloak
  scopes: openid profile email
  providerName: keycloak
```

Redirect URL format: `https://<vikunja-host>/auth/openid/<provider-name-lowercase>` — matches the provider name value.

### Keycloak Client Settings
Realm `vikunja`:
- Client ID: `vikunja-web`
- Public Client: On (or confidential with secret + set `confidentialClient: true` in values and create secret)
- Root URL: `https://vikunja.misskecupbung.xyz`
- Valid Redirect URIs: `/auth/openid/keycloak`
- Web Origins: `https://vikunja.misskecupbung.xyz`

### Common Symptoms
| Symptom | Cause | Fix |
|---------|-------|-----|
| `providers` is `null` | Single provider (normal) or init race | Try login; restart deployment; set `providerName` |
| Redirect 403 from Keycloak | Redirect URI mismatch | Align Keycloak client redirect with Vikunja value |
| Iframe timeout | Host/proxy headers mismatch | Ensure DNS correct; hostname strict disabled |
| 500 after auth | Client type mismatch | Check public vs confidential settings |
| Discovery fails | DNS / egress block | Curl well-known from debug pod |

### Debug Commands
```bash
curl -s https://keycloak.misskecupbung.xyz/realms/vikunja/.well-known/openid-configuration | jq .issuer
kubectl rollout restart deploy/vikunja
kubectl logs deploy/vikunja -c api | grep -i openid || true
kubectl run oidc-debug --rm -it --image=alpine:3 -- sh -c 'apk add --no-cache curl; curl -s https://keycloak.misskecupbung.xyz/realms/vikunja/.well-known/openid-configuration | grep authorization_endpoint'
```

### Multi-Provider Example
```
auth:
  openid:
    enabled: true
    providers:
      - name: keycloak
        authurl: https://keycloak.misskecupbung.xyz/realms/vikunja
        clientid: vikunja-web
      - name: google
        authurl: https://accounts.google.com
        clientid: <google-client-id>
```
Each provider requires its own redirect URL: `/auth/openid/keycloak`, `/auth/openid/google`.

### Checklist
- [ ] Realm + client exists
- [ ] Redirect URI matches provider name
- [ ] Pod restarted after config change
- [ ] Issuer reachable (inside & outside cluster)
- [ ] Scopes include `openid`
- [ ] Time sync (no large clock skew)

Defaults are for development. Review security (passwords, network access, TLS) before production use.
>>>>>>> 3a55eab (change cloud aql proxy)
=======
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
>>>>>>> a14647b (add configmap)
