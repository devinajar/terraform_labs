### The bucket for the csv
resource "google_storage_bucket" "csv_bucket" {
  name     = "${var.project_id}-${var.csv_bucket_name}"
  location = var.region
}

### The bucket for the cloud function
resource "google_storage_bucket" "cloudfunctions_bucket" {
  name     = "${var.project_id}-${var.cf_bucket_name}"
  location = var.region
}

resource "google_storage_bucket_object" "cf_source_file" {
  name   = "source.zip"
  bucket = google_storage_bucket.cloudfunctions_bucket.name
  source = "./source/source.zip"
}

### Cloud function triggered upon file upload
resource "google_cloudfunctions2_function" "execute_transfer_job" {
  depends_on  = [google_bigquery_data_transfer_config.data_transfer_job]
  project     = var.project_id
  name        = "execute_transfer_job"
  location    = var.region
  description = "Executes the Data transfer job"

  build_config {
    runtime     = "nodejs18"
    entry_point = "startDataTransfer"
    source {
      storage_source {
        bucket = google_storage_bucket.cloudfunctions_bucket.name
        object = google_storage_bucket_object.cf_source_file.name
      }
    }
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.storage.object.v1.finalized"
    retry_policy   = "RETRY_POLICY_DO_NOT_RETRY"
    # service_account_email = google_service_account.cloud_function_sa.email

    event_filters {
      attribute = "bucket"
      value     = google_storage_bucket.csv_bucket.name
    }
  }

  service_config {
    available_memory                 = "256M"
    ingress_settings                 = "ALLOW_INTERNAL_ONLY"
    max_instance_count               = 1
    max_instance_request_concurrency = 1
    min_instance_count               = 0
    timeout_seconds                  = 540
    # service_account_email            = google_service_account.cloud_function_sa.email
    environment_variables = {
      PROJECT_ID  = "${var.project_id}",
      TRANSFER_ID = "${google_bigquery_data_transfer_config.data_transfer_job.id}"
      REGION      = "${var.region}"
    }
  }
}

### Dataset and tables
resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.dataset_id
  location   = var.region
}

resource "google_bigquery_table" "temp_table" {
  dataset_id          = google_bigquery_dataset.dataset.dataset_id
  table_id            = "${var.project_id}_temp-table"
  schema              = file(var.path_to_schema)
  deletion_protection = false
}

resource "google_bigquery_table" "consolidation_table" {
  dataset_id          = google_bigquery_dataset.dataset.dataset_id
  table_id            = "${var.project_id}_consolidation-table"
  schema              = file(var.path_to_schema)
  deletion_protection = false
}

resource "google_service_account" "datatransfer_service_account" {
  account_id   = "dataset-service-account"
  display_name = "Dataset Service Account"
}

resource "google_project_iam_member" "data_transfer_premission" {
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.datatransfer_service_account.email}"
  project = var.project_id
}

resource "google_storage_bucket_iam_binding" "adjust-rosseca-binding" {
  bucket = google_storage_bucket.csv_bucket.name
  role   = "roles/storage.admin"
  members = [
    "serviceAccount:${google_service_account.datatransfer_service_account.email}"
  ]
}

resource "google_bigquery_data_transfer_config" "data_transfer_job" {
  depends_on             = [google_project_iam_member.data_transfer_premission]
  display_name           = "auto_transfer_job"
  location               = var.region
  data_source_id         = "google_cloud_storage"
  destination_dataset_id = google_bigquery_dataset.dataset.dataset_id
  service_account_name   = google_service_account.datatransfer_service_account.email

  params = {
    data_path_template              = "gs://${google_storage_bucket.csv_bucket.name}/*.csv"
    file_format                     = "CSV"
    write_disposition               = "APPEND"
    destination_table_name_template = google_bigquery_table.temp_table.table_id
    ignore_unknown_values           = "true"
    skip_leading_rows               = 1
  }
}