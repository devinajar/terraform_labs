### The bucket for the csv
resource "google_storage_bucket" "csv_bucket" {
  name     = var.csv_bucket_name
  location = var.region
}

### The bucket for the cloud function
resource "google_storage_bucket" "cloudfunctions_bucket" {
  name     = var.cf_bucket_name
  location = var.region
}

resource "google_storage_bucket_object" "cf_source_file" {
  name   = "cf_source_function.zip"
  bucket = google_storage_bucket.cloudfunctions_bucket.name
  source = "./cf_source/cf_source_function.zip"
}

### Service account for the cloud function to be triggered
resource "google_service_account" "cloud_function_sa" {
  account_id   = "cloud-function-sa"
  display_name = "Cloud Function Service Account"
}

resource "google_project_iam_member" "function_sa_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.cloud_function_sa.email}"
}

resource "google_project_iam_member" "eventarc_admin" {
  project = var.project_id
  role    = "roles/eventarc.admin"
  member  = "serviceAccount:${google_service_account.cloud_function_sa.email}"
}

resource "google_project_iam_member" "iam_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cloud_function_sa.email}"
}

resource "google_project_iam_member" "eventarc_receive_event" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.cloud_function_sa.email}"
}

resource "google_project_iam_member" "run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.cloud_function_sa.email}"
}

### Cloud function triggered upon file upload
resource "google_cloudfunctions2_function" "execute_transfer_job" {
  name        = "execute_transfer_job"
  location    = var.region
  description = "Executes the Data transfer job"

  build_config {
    runtime = "python311"
    source {
      storage_source {
        bucket = google_storage_bucket.cloudfunctions_bucket.name
        object = google_storage_bucket_object.cf_source_file.name
      }
    }
  }

  event_trigger {
    trigger_region        = var.region
    event_type            = "google.cloud.storage.object.v1.finalized"
    retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"
    service_account_email = google_service_account.cloud_function_sa.email

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
    service_account_email            = google_service_account.cloud_function_sa.email
  }
}