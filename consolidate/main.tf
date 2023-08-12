provider "google" {
  credentials = file("path")
  project = "project_id"
  region = "eu-west1"
}

# Account Settings
### Service account
resource "google_service_account" "data_loader" {
  account_id = "data-loader-service-account"
  display_name = "Data Loader Service Account"
}
### Account member
resource "google_project_iam_member" "data_loader_binding" {
  project = var.project_id
  role = "roles/bigquery.dataEditor"
  member = "serviceAccount:${google_service_account.data_loader.email}"
}

# Storage resources
resource "google_storage_bucket" "csv_bucket" {
  name = "csv-bucket"
  location = "europe-west2"
  uniform_bucket_level_access = true
}

resource "google_bigquery_dataset" "dataset" {
  dataset_id = "consolidation_dataset"
}

resource "google_bigquery_table" "temp_table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id = "temp_table"

  external_data_configuration {
    source_format = "CSV"
    autodetect = true
    csv_options {
      skip_leading_rows = 1
    }
  }
}


