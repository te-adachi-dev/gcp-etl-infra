terraform {
  backend "gcs" {
    bucket = "terraform-state-20250628"
    prefix = "terraform/state/dev"
  }
}
