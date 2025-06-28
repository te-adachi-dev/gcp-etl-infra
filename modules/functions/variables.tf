variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "input_bucket" {
  description = "Input bucket name"
  type        = string
}

variable "output_bucket" {
  description = "Output bucket name"
  type        = string
}
