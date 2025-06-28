provider "google" {
  project = var.project_id
  region  = var.region
}

# State管理用のバケットは既に手動で作成済みなのでコメントアウト
# resource "google_storage_bucket" "terraform_state" {
#   name     = "terraform-state-20250628"
#   location = var.region
#   
#   versioning {
#     enabled = true
#   }
#   
#   lifecycle_rule {
#     condition {
#       age = 30
#     }
#     action {
#       type = "Delete"
#     }
#   }
# }

# データレイク用ストレージ
module "storage" {
  source      = "./modules/storage"
  project_id  = var.project_id
  region      = var.region
  environment = var.environment
}

# Cloud Functions
module "functions" {
  source         = "./modules/functions"
  project_id     = var.project_id
  region         = var.region
  environment    = var.environment
  input_bucket   = module.storage.input_bucket_name
  output_bucket  = module.storage.output_bucket_name
}

# Workflows
module "workflows" {
  source      = "./modules/workflows"
  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  function_id = module.functions.function_id
}

# BigQuery
module "bigquery" {
  source      = "./modules/bigquery"
  project_id  = var.project_id
  region      = var.region
  environment = var.environment
}