provider "google" {
  project = var.project_id
  region  = "europe-west1"
}

# Bucket creation
### Service account that will load the data into the bucket
resource "google_service_account" "data_loader" {
  account_id   = "data-loader-service-account"
  display_name = "Data Loader Service Account"
}

### Bind service account to bucket
resource "google_project_iam_binding" "data_loader_binding" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  members = [
    "serviceAccount:${google_service_account.data_loader.email}"
  ]
}
### The bucket itself
resource "google_storage_bucket" "csv_bucket" {
  name                        = var.bucket_name
  location                    = "europe-west2"
  uniform_bucket_level_access = true
}

# Database creation
### Dataset creation
resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.dataset_id
}

### Temporary table where the csv will be loaded
resource "google_bigquery_table" "daily_temp_table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = var.temp_table_id

  external_data_configuration {
    source_format = "CSV"
    autodetect    = true
  }
}

### Main table where consiolidated data goes
resource "google_bigquery_table" "main_table" {
  dataset_id          = google_bigquery_dataset.dataset.dataset_id
  table_id            = var.main_table_id
  deletion_protection = false
  schema              = file("path/to/file")
}

# [START] Jobs for consolidation
resource "google_bigquery_data_transfer_config" "transfer_job" {
  display_name   = "Data Transfer Job"
  data_source_id = "google_cloud_storage"

  params = <<PARAMS
{
  "fileFormat": "CSV",
  "destinationTableIdTemplate": "${google_bigquery_table.temp_table.table_id}",
  "bucketName": "${google_storage_bucket.csv_bucket.name}",
  "ignoreUnknownValues": false,
  "fieldDelimiter": ",",
  
"skipLeadingRows": 1
}
PARAMS
}

resource "google_pubsub_topic" "data_loaded_topic" {
  name = "your-data-loaded-topic"
}

resource "google_cloudfunctions_function" "merge_function" {
  name        = var.merge_function_name
  description = "Function to trigger merge operation after data loading"
  runtime     = "go113"

  source_archive_bucket = var.cloud_function_bucket
  source_archive_object = var.cloud_function_zip_path
  entry_point           = "mergeFunction"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_bigquery_data_transfer_config.transfer.pubsub_topic
  }

  labels = {
    "deployment-tool" = "terraform"
  }
}

