variable "project_id" { } # Defined in `terraform.tfvars` for security

variable "region" {
  default = "europe-west1"
}

variable "csv_bucket_name" {
  default = "${var.project_id}_csv_bucket"
}

variable "cf_bucket_name" {
  default = "${var.project_id}_cf_bucket"
}