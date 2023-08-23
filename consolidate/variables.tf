variable "project_id" {}
variable "credentials_file" {}

variable "region" {
  default = "europe-west1"
}

variable "csv_bucket_name" {
  default = "labs-for-ltech_csv_bucket"
}

variable "cf_bucket_name" {
  default = "labs-for-ltech_cf_bucket"
}