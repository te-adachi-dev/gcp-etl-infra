resource "google_storage_bucket" "input_bucket" {
  name     = "${var.environment}-input-bucket-20250628"
  location = var.region
  
  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket" "output_bucket" {
  name     = "${var.environment}-output-bucket-20250628"
  location = var.region
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

output "input_bucket_name" {
  value = google_storage_bucket.input_bucket.name
}

output "output_bucket_name" {
  value = google_storage_bucket.output_bucket.name
}
