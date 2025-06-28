resource "google_storage_bucket" "function_bucket" {
  name     = "${var.environment}-function-source-20250628"
  location = var.region
}

resource "google_storage_bucket_object" "function_zip" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = "${path.module}/function-source.zip"
}

resource "google_cloudfunctions_function" "data_processor" {
  name        = "${var.environment}-data-processor"
  runtime     = "python39"
  region      = var.region
  
  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.function_zip.name
  
  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = var.input_bucket
  }
  
  entry_point = "process_data"
  
  environment_variables = {
    OUTPUT_BUCKET = var.output_bucket
  }
}

output "function_id" {
  value = google_cloudfunctions_function.data_processor.id
}
