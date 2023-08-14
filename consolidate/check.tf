provider "google" {
  credentials = file(var.admin_service_account_key)
  project     = var.project_id
  region      = "us-central1"
}

resource "google_service_account" "data_loader" {
  account_id   = "data-loader-service-account"
  display_name = "Data Loader Service Account"
}

resource "google_project_iam_binding" "data_loader_binding" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  
  members = [
    "serviceAccount:${google_service_account.data_loader.email}"
  ]
}

resource "google_storage_bucket" "csv_bucket" {
  name     = var.bucket_name
  location = "us-central1"
  versioning {
    enabled = true
  }
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.dataset_id
}

resource "google_bigquery_table" "temp_table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = var.temp_table_id

  external_data_configuration {
    source_format = "CSV"
    autodetect    = true
    csv_options {
      skip_leading_rows = 1
    }
  }
}

resource "google_bigquery_table" "main_table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = var.main_table_id

  schema {
    name = "field1"
    type = "STRING"
    mode = "NULLABLE"
  }
}

resource "google_bigquery_data_transfer_config" "transfer" {
  display_name = "Your Data Transfer Config"
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

