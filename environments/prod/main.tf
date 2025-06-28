module "infrastructure" {
  source      = "../../"
  project_id  = var.project_id
  region      = var.region
  environment = var.environment
}
