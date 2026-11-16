variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region for Always-Free VM"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone for Always-Free VM"
  type        = string
  default     = "us-central1-a"
}
