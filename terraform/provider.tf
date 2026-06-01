terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}

# Definição do projeto GCP
provider "google" {
  project = var.project_id
  region  = var.region
}