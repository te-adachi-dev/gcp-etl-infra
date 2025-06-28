resource "google_bigquery_dataset" "data_lake" {
  dataset_id  = "${var.environment}_data_lake"
  location    = var.region
  description = "Data Lake Dataset"
  
  default_table_expiration_ms = 2592000000  # 30 days
  
  labels = {
    environment = var.environment
  }
}

resource "google_bigquery_table" "raw_data" {
  dataset_id = google_bigquery_dataset.data_lake.dataset_id
  table_id   = "raw_data"
  
  time_partitioning {
    type  = "DAY"
    field = "created_at"
  }
  
  schema = <<EOF
[
  {
    "name": "id",
    "type": "STRING",
    "mode": "REQUIRED"
  },
  {
    "name": "data",
    "type": "JSON",
    "mode": "NULLABLE"
  },
  {
    "name": "created_at",
    "type": "TIMESTAMP",
    "mode": "REQUIRED"
  }
]
EOF
}
