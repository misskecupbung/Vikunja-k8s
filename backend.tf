terraform {
  # GCS backend configuration. Bucket & prefix are supplied via terraform init -backend-config flags.
  # Workspaces (dev, prod) will create separate state objects under the same prefix automatically (env:<workspace> naming).
  backend "gcs" {}
}
