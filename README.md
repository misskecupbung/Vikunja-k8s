# Vikunja Kubernetes & GKE Terraform Deployment

Infrastructure-as-Code + Helm chart to deploy the Vikunja Todo application on a Google Kubernetes Engine (GKE) cluster. Includes optional managed Cloud SQL (PostgreSQL) vs. self‑hosted Postgres, optional Keycloak IAM integration, and operational scripts.

## Repository Structure

```
modules/            # Terraform reusable modules (network, gke, cloudsql)
charts/vikunja/     # Helm chart for the Vikunja application
scripts/            # Helper scripts (deploy, destroy, monitor, debug, keycloak values)
scripts/k8s/        # Raw k8s manifests (self-hosted postgres alternative)
environments/       # tfvars per environment (dev, prod)
main.tf, variables.tf, outputs.tf  # Root Terraform
```

## Tooling Choices & Rationale

1. Terraform: Provision GCP infrastructure (network, GKE cluster, Cloud SQL) declaratively, enabling stateful, reviewable changes and environment separation via tfvars.
2. Helm: Package application level k8s manifests with parameterization (DB host, Cloud SQL proxy sidecar, autoscaling, ingress, network policy). Helm supports easy upgrades and rollback for the app.
3. Managed DB (Cloud SQL) (default): Provides automated backups, PITR, HA (regional), patching, and reduces operational toil vs. self-hosting. A self-hosted Postgres StatefulSet manifest is supplied for completeness / local or cost‑sensitive scenarios.
4. Optional Keycloak: Industry-standard OpenID Connect provider for IAM. Can be deployed via existing community/bitnami chart using `scripts/keycloak-values.yaml` as override.

## Database Strategy Justification

Production defaults to managed Cloud SQL due to:
* High availability (regional) & automated failover.
* Built-in backups + point-in-time recovery.
* Reduced patching & security burden (managed OS, minor version updates).
* Easier scaling (storage auto-resize, tier changes) without downtime.

Self-hosted Postgres is included (StatefulSet + PVC) for local development, air‑gapped deployments, or cost constraints. Trade-offs: manual backups, upgrades, HA complexity (would need Patroni / Crunchy Operator), greater ops overhead.

## Network & Performance Optimizations

* VPC-native GKE with secondary IP ranges for Pods/Services → avoids IP exhaustion and enables alias IPs.
* Calico NetworkPolicy enabled for least privilege east-west traffic controls.
* NEGs (service annotation) for better L7 load balancing & HTTP health checks.
* HorizontalPodAutoscaler + optional Vertical Pod Autoscaler at cluster level.
* PodDisruptionBudget to maintain availability during node upgrades.
* Resource requests/limits set for predictable scheduling; can tune after observing metrics.
* Separate node pool (extend by adding another module) could isolate workloads by performance / cost class.
* Readiness & liveness probes for fast failure detection and robust rollout gating.
* Workload Identity (if enabled) to avoid long‑lived service account keys.

## Security Considerations

* NetworkPolicy restricts ingress to necessary ports only.
* Secrets separated (DB password). For production replace inline secrets with Secret Manager + CSI driver or external-secrets operator.
* Optionally enable private SQL + Cloud SQL Auth Proxy sidecar to avoid public DB exposure.
* IAM granularity with Workload Identity instead of static keys.

## Keycloak Integration (Optional)

Deploy Keycloak (example using bitnami chart):

```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade --install keycloak bitnami/keycloak -f scripts/keycloak-values.yaml
```

Update `values.yaml` of Vikunja with `keycloak.enabled=true` and set `keycloak.issuer` to the deployed realm URL. Adjust Vikunja config map to include client secret (store in a secret, not plaintext) for production.

## Deploy (Dev Example)

Prerequisites: `gcloud`, `terraform >=1.6`, `helm`, authenticated to GCP, project created.

### 1. Create GCS bucket for Terraform state

```
PROJECT_ID=$YOUR_PROJECT
gsutil mb -p "$PROJECT_ID" -c STANDARD -l europe-west1 gs://$PROJECT_ID-tf-state
gsutil versioning set on gs://$PROJECT_ID-tf-state
```

### 2. Create Terraform service account + Workload Identity Federation (for GitHub CI)

```
gcloud iam service-accounts create terraform --display-name="Terraform SA"
gcloud projects add-iam-policy-binding $PROJECT_ID \
	--member="serviceAccount:terraform@$PROJECT_ID.iam.gserviceaccount.com" \
	--role="roles/owner" # narrow later

# (Optional) Workload Identity Federation for GitHub
gcloud iam workload-identity-pools create github-pool --project=$PROJECT_ID --location=global --display-name="GitHub Pool"
gcloud iam workload-identity-pools providers create-oidc github-provider \
	--project=$PROJECT_ID --location=global --workload-identity-pool=github-pool \
	--display-name="GitHub Provider" --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
	--issuer-uri="https://token.actions.githubusercontent.com"
gcloud iam service-accounts add-iam-policy-binding terraform@$PROJECT_ID.iam.gserviceaccount.com \
	--project=$PROJECT_ID \
	--role="roles/iam.workloadIdentityUser" \
	--member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/attribute.repository/OWNER/REPO"
```

Add these GitHub repository secrets:

* `GCP_PROJECT_ID` – your project id
* `GCP_REGION` – e.g. europe-west1
* `GCP_WIF_PROVIDER` – full resource name of workload identity provider (e.g. `projects/123456789/locations/global/workloadIdentityPools/github-pool/providers/github-provider`)
* `GCP_TERRAFORM_SA` – `terraform@PROJECT_ID.iam.gserviceaccount.com`
* `TF_STATE_BUCKET` – name of your state bucket

### 3. Initialize & deploy locally (dev)

```
export TF_VAR_db_password="$(openssl rand -base64 20)" # or export from a secret manager
terraform init -backend-config="bucket=$PROJECT_ID-tf-state" -backend-config="prefix=terraform/dev"
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars -auto-approve

gcloud container clusters get-credentials $(terraform output -raw gke_cluster_name) --region $(terraform output -raw region 2>/dev/null || echo europe-west1)
helm upgrade --install vikunja charts/vikunja \
	--set cloudsql.instanceConnectionName="$(terraform output -raw cloudsql_instance)" \
	--set postgres.host=127.0.0.1 # via cloud sql proxy sidecar
```

### 4. Trigger GitHub Actions
Push a branch / open PR to see `terraform plan` comment; merge to `main` for automatic apply (prod tfvars).

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

## Further Enhancements (Future Work)

* Add Terraform module for separate node pools (spot vs. on-demand).
* Implement External Secrets + Secret Manager integration.
* Add CI pipeline (GitHub Actions) for terraform plan + helm lint + kubeval.
* Enable GKE Autopilot evaluation (cost vs. control trade-off).
* Add Keycloak realm & client bootstrap automation (Realm JSON + kcadm script).

## Disclaimer

This is a reference implementation for interview purposes; hard-coded sample values (passwords, hosts) must be replaced with secure secret management and environment-specific overrides before production use.

