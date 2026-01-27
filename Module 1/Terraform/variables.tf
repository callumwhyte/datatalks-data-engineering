variable "credentials" {
  description = "My Credentials"
  default     = "./keys/my-creds.json"
}

variable "bq_dataset_name" {
  description = "My BigQuery Dataset Name"
  default     = "demo_dataset"
}

variable "gcs_bucket_name" {
  description = "My GCS Bucket Name"
  default     = "de-terraform-485418-demo-bucket"
}

variable "gcp_project" {
  description = "GCP Project ID"
  default     = "de-terraform-485418"
}
variable "gcp_region" {
  description = "GCP Region"
  default     = "europe-west2"
}

variable "location" {
  description = "Larger location"
  default     = "EU"
}
