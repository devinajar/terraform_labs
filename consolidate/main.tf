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

resource "google_storage_bucket_object" "csv" {
  name = "*.csv"
  bucket = google_storage_bucket.csv_bucket.name
  source = "${path.module}/*.csv"
}
