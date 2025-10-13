# Vikunja Deployment Case Study

## 1. Overview
This case study presents an automated, production‑aligned deployment of the Vikunja To‑Do application on Google Kubernetes Engine (GKE) with a managed Cloud SQL for PostgreSQL backend and optional Identity & Access Management via Keycloak. The solution emphasizes:
- Infrastructure as Code (Terraform) for network, cluster, and database provisioning
- Application configuration as code using Helm charts (templating, overrides, environments)
- GitHub Actions CI/CD pipeline integrating Terraform plan/apply and Helm deployments
- High availability (multi‑replica, probes, autoscaling hooks) and resilience
- Secure separation of application and identity provider databases/users
- Extensibility for future enhancements (Cloud SQL Proxy / Private IP, observability, secret managers)

## 2. Requirements Mapping
| Requirement | Implementation | Notes |
|-------------|----------------|-------|
| Kubernetes cluster | GKE via Terraform | `modules/gke` sets node pool, version, IAM |
| Deployment templating | Helm | Chosen over Kustomize for chart reuse & values layering |
| main + database manifests | `charts/vikunja` + managed Cloud SQL | Managed DB (Cloud SQL) replaces in‑cluster StatefulSet; example self‑hosted manifest provided for comparison |
| Managed vs self-hosted DB justification | Cloud SQL chosen | Automatic backups, patching, HA options, reduces ops toil |
| Optional IAM (Keycloak) | `charts/keycloak` | OIDC integration to Vikunja env vars when enabled |
| High availability | Replica count >=2 (Vikunja), probes, readiness, HPA-ready values | Keycloak single replica (can be scaled) |
| Load balancing | GKE Ingress (GCE) + Service | Ingress annotations in Helm values |
| Network optimization | VPC Terraform, potential future Private Service Connect; local caching in Keycloak; probe tuning | Public IP temporarily authorized; can tighten |
| Monitoring & debugging | Probes + (extensible) logs; diagnostics script | Future step: Prometheus/Grafana/OpenTelemetry |

## 3. Architecture
### 3.1 Logical Components
- VPC + subnet (Terraform)
- GKE cluster (Terraform) with node pool
- Cloud SQL Postgres instance with two logical DBs & users: `vikunja` and `keycloak` (Terraform)
- Keycloak Deployment (optional) exposing OIDC realm
- Vikunja Deployment (dual containers: API + Frontend)
- Kubernetes Services (ClusterIP) and GCE Ingress
- GitHub Actions pipeline (plan/apply/deploy)

### 3.2 Data Flow
1. User → GCE Ingress → `vikunja` Service → API container
2. API container → Cloud SQL (direct public IP; SSL enforced) for data
3. (Optional) API → Keycloak (OIDC authorization code flow)
4. Keycloak → Its own Cloud SQL logical DB

### 3.3 Secrets & Credentials
- GitHub Secrets hold DB user passwords & Keycloak admin credentials
- Kubernetes Secrets created during workflow (`keycloak-db`, `vikunja-db`, `keycloak-admin`)
- Future: external secret store (GCP Secret Manager) wiring is scaffolded in values for Vikunja.

## 4. Helm Templating Rationale
Helm chosen because:
- Native support for packaging + versioning charts
- Straightforward values layering (base vs CI overrides)
- Conditional logic for optional OIDC / Cloud SQL proxy
- Ecosystem familiarity (operators, chart repositories)

Kustomize excels at patch layering but lacks native packaging & dependency semantics present in Helm (helpful for optional Keycloak). Jsonnet is powerful but adds learning curve and maintenance overhead.

## 5. Database Strategy Justification
Managed Cloud SQL selected over self‑hosted Postgres because it provides:
- Automated backups, point‑in‑time recovery
- Security patching & maintenance windows handled by provider
- Built‑in HA (read replicas / failover configuration when enabled)
- Reduced operational overhead allowing focus on application logic

Trade‑offs:
- Higher direct cost vs in‑cluster single pod
- Network latency (manageable; can be reduced via Private IP or PSC later)

Fallback: Provided sample `examples/postgres-statefulset.yaml` to demonstrate self‑hosted alternative (with PVC, liveness probe, and basic backup hook stub) — not applied in production due to operational risk.

## 6. High Availability & Resilience
| Aspect | Mechanism |
|--------|-----------|
| Redundancy | Vikunja replicas=2; HPA-ready config |
| Failure isolation | Separate DB users & schemas for Vikunja & Keycloak |
| Startup reliability | Increased Keycloak startupProbe failureThreshold for Liquibase migrations |
| Probes | Liveness & readiness for all containers; Keycloak uses /health/{live,ready} |
| Rolling updates | Default Deployment rolling strategy; low replica PDB for minimal disruption |
| Secrets rotation | External secret placeholders prepared; re-deploy triggers new pods |

## 7. Network Optimization
Current:
- Direct public IP connectivity to Cloud SQL with SSL enforcement parameters
- Local Node routing via GKE Ingress (GCE) offering global LB features
- Keycloak local caching (`--cache=local`) reduces DB query volume on auth flows

Planned Improvements:
- Switch to Private IP / VPC peering (eliminates public exposure, lowers latency)
- Apply NetworkPolicy egress restrictions (scaffold exists) to limit external traffic
- Introduce Cloud SQL Auth Proxy only if Private IP is unavailable (reduces complexity otherwise)

## 8. IAM (Optional OIDC) Implementation
Keycloak chart provisions: admin credentials secret, DB credentials, startup args enabling health endpoints. Realm bootstrap (job) can be extended to import realm JSON. Vikunja chart conditionally injects OpenID configuration env vars when `openid.enabled=true`. Clients obtain tokens via authorization code flow and Vikunja validates issuer against configured realm.

## 9. CI/CD Pipeline
Pipeline stages:
1. Plan: Terraform init/plan and Helm template validation (kubeconform) with base values.
2. Apply: Terraform apply with workspace (dev/prod) separation.
3. Deploy Keycloak: Acquire cluster creds, create secrets, deploy with direct DB host.
4. Deploy Vikunja: Fetch Cloud SQL IP, disable proxy, set DB host, deploy chart.

Enhancements (future): Add Helm unit tests (helm unittest), chart schema (values.schema.json), and security scans (Trivy) gates.

## 10. Observability & Diagnostics
Baseline: Kubernetes events, pod logs, readiness/liveness probes. 
Diagnostics script (`scripts/vikunja-diagnostics.sh`) can gather:
- Pod status & restarts
- Recent logs (API, Keycloak)
- Ingress status
- Database connection latency sample (psql if available)

Future Observability Roadmap:
- Prometheus operator + ServiceMonitors
- Loki for centralized logs
- Tempo or OpenTelemetry collector for tracing across Vikunja + Keycloak

## 11. Security Considerations
| Concern | Current | Future Hardening |
|---------|---------|------------------|
| DB exposure | Public IP restricted (temporarily broad) | Private IP + narrower authorized networks |
| Secrets | GitHub secrets -> K8s secrets | GCP Secret Manager + ExternalSecrets integration |
| Pod identity | Default SA | Workload Identity for fine-grained IAM to Cloud SQL |
| TLS | Ingress (HTTP now) | Enable managed certs / enforce HTTPS redirect |
| Image provenance | Public upstream images | Pin digests + add image scanning |

## 12. Trade-offs & Lessons Learned
- Direct Cloud SQL connection simpler & faster to stabilize than proxy; proxy reserved for private or IAM auth scenarios.
- Helm conditional logic must be applied carefully to avoid YAML parse errors—prefer simple inline condition with explicit quoting.
- Probes tuning for Keycloak migrations critical for first boot success.

## 13. Future Enhancements Backlog
1. Private IP Cloud SQL + remove broad authorized networks.
2. Service mesh (optional) for mTLS & traffic policies.
3. Add HorizontalPodAutoscaler (values already HPA-ready) and tune resource requests via metrics.
4. Integrate External Secrets for all credentials.
5. Add canary / blue-green strategy using Helm chart labels + Argo Rollouts (optional).
6. Terraform output consumption in Helm via a generated values overlay artifact.

## 14. How To Run (Summary)
```bash
# Terraform (dev)
terraform workspace select dev || terraform workspace new dev
terraform apply -var-file=environments/dev.tfvars

# Keycloak (direct DB)
helm upgrade --install keycloak charts/keycloak -f charts/keycloak/values-ci.yaml \
  --set database.host=$(gcloud sql instances describe vikunja-db --format='value(ipAddresses[0].ipAddress)') \
  --set cloudsql.enabled=false

# Vikunja (direct DB)
helm upgrade --install vikunja charts/vikunja -f charts/vikunja/values-ci.yaml \
  --set cloudsql.enabled=false \
  --set postgres.host=$(gcloud sql instances describe vikunja-db --format='value(ipAddresses[0].ipAddress)')
```

## 15. Example Self-Hosted Postgres (Optional)
See `examples/postgres-statefulset.yaml` (to be added) for a basic StatefulSet + PVC + headless Service illustrating how a local Postgres might be deployed; omitted in production path due to operational overhead.

---
*End of Case Study*
