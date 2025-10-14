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

Dev-focused deployment of Vikunja on Google Kubernetes Engine using Terraform (infra) and Helm (apps). Optional Cloud SQL Postgres and Keycloak for OIDC. Shared GCE Ingress with a global static IP.

## Overview
Provisioned resources:
- VPC + subnet + secondary IP ranges (pods/services)
- GKE cluster (workload identity enabled)
- Optional Cloud SQL instance (Vikunja + optional Keycloak DB)
- Global static IP & shared ingress (`charts/platform`)
- Helm charts: `vikunja`, `keycloak`, `platform`

## Quick Start
Prerequisites: terraform >= 1.6, gcloud, helm.
```bash
PROJECT_ID="your-project"
REGION="europe-west1"
gsutil mb -p "$PROJECT_ID" -l $REGION gs://$PROJECT_ID-tf-state || true
terraform init -backend-config="bucket=$PROJECT_ID-tf-state" -backend-config="prefix=terraform"
terraform workspace new dev 2>/dev/null || true
terraform workspace select dev
export TF_VAR_vikunja_db_password="$(openssl rand -base64 20)"
export TF_VAR_keycloak_db_password="$(openssl rand -base64 20)"
terraform apply -var-file=environments/dev.tfvars -auto-approve

gcloud container clusters get-credentials $(terraform output -raw gke_cluster_name) --region $REGION
helm upgrade --install vikunja charts/vikunja \
  --set cloudsql.instanceConnectionName="$(terraform output -raw cloudsql_instance)" \
  --set postgres.host=127.0.0.1
```
Port‑forward if no DNS yet:
```bash
kubectl port-forward svc/vikunja 8080:80
open http://localhost:8080
```

## Core Vikunja Values
| Key | Purpose |
|-----|---------|
| postgres.host | Database hostname or proxy localhost |
| ingress.host | Public base URL |
| openid.enabled | Enable OIDC integration |
| openid.issuer | OIDC issuer (Keycloak realm URL) |
| resources.* | Pod resource requests/limits |

`VIKUNJA_SERVICE_PUBLICURL` derives from `ingress.host`.

## Optional: Keycloak
Install Keycloak (if using OIDC):
```bash
helm upgrade --install keycloak charts/keycloak \
  --set cloudsql.enabled=true \
  --set cloudsql.instanceConnectionName="$(terraform output -raw cloudsql_instance)"
```
Then ensure `openid.*` settings in Vikunja match the Keycloak realm.

## Private Cloud SQL (Recommended)
This setup can run Cloud SQL over private VPC peering (enabled by default if you set `enable_public_ip=false` and pass the VPC self link). Current configuration already disables the public IPv4 and establishes a service networking connection:

Root module snippet:
```
module "cloudsql" {
  # ...
  enable_public_ip = false
  private_network  = module.network.network
}
```
Network module provisions:
```
google_compute_global_address.private_service_range (purpose=VPC_PEERING)
google_service_networking_connection.private_vpc_connection
```
If converting an existing instance from public to private, Terraform will need to recreate the instance (data migration required). For production, perform a dump/restore:
```bash
pg_dump -h <old_public_ip> -U vikunja vikunja > vikunja.sql
# recreate with private IP
psql -h <new_private_ip> -U vikunja -d vikunja -f vikunja.sql
```

## CI/CD
GitHub Actions workflow stages:
- Plan: terraform plan + helm lint + kubeconform
- Apply: terraform apply
- Deploy: helm upgrades for keycloak, vikunja, platform ingress

## Rollback
```bash
helm rollback vikunja <revision>
```

## Cleanup
```bash
terraform workspace select dev
terraform destroy -var-file=environments/dev.tfvars -auto-approve
```

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
