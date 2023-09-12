variable "project_id" {}
variable "credentials_file" {}

variable "region" {
  default = "europe-west1"
}

variable "csv_bucket_name" {
  default = "csv_bucket"
}

variable "cf_bucket_name" {
  default = "cf_bucket"
}

variable "dataset_id" {
  default = "consolidation_dataset"
}

variable "path_to_schema" {
  default = "schema.json"
}