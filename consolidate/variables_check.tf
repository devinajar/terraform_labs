variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "admin_service_account_key" {
  description = "Path to the admin service account key JSON file"
  type        = string
}

variable "service_account_key" {
  description = "Path to the service account key JSON file"
  type        = string
}

variable "bucket_name" {
  description = "Name of the Cloud Storage bucket"
  type        = string
}

variable "dataset_id" {
  description = "ID of the BigQuery dataset"
  type        = string
}

variable "main_table_id" {
  description = "ID of the main BigQuery table"
  type        = string
}

variable "temp_table_id" {
  description = "ID of the temporary BigQuery table"
  type        = string
}

variable "cloud_function_bucket" {
  description = "Name of the Cloud Storage bucket for the Cloud Function source code"
  type        = string
}

variable "cloud_function_zip_path" {
  description = "Path to the Cloud Function source code zip file"
  type        = string
}

variable "merge_function_name" {
  description = "Name of the Cloud Function"
  type        = string
}

