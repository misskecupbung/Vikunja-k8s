terraform {
  backend "gcs" {
    bucket  = "CHANGE_ME_STATE_BUCKET"   # e.g. vikunja-tf-state-prod
    prefix  = "terraform/state"          # folder within bucket
    # impersonate_service_account = "tf-state-wi@PROJECT_ID.iam.gserviceaccount.com" (optional)
  }
}
