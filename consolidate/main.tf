provider "google" {
  project = var.project_id
  region  = var.region
}

# Bucket creation
### The bucket
resource "google_storage_bucket" "csv_bucket" {
  name     = var.bucket_name
  location = var.region # ?? Check if this is correct
}

### Service account that will load the data into the bucket
resource "google_service_account" "data_loader" {
  account_id   = "data-loader-service-account"
  display_name = "Data Loader Service Account"
}

### Binding of the SA with the necessary role
resource "google_project_iam_binding" "data_loader_binding" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  members = [
    "serviceAccount:${google_service_account.data_loader.email}"
  ]
}


