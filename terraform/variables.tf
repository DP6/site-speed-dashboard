#######################################
# Local Configuration Files
#######################################
locals {
  cf_name                          = "${var.project_prefix}-site-speed-dashboard"
  project_name                     = "site-speed-dashboard"
  cf_entry_point                   = "getUrls"
  bq_table_psi_metrics_results     = "psi_metrics_results"
  bq_table_crux_table              = "crux_table"
  bq_table_psi_suggestions_results = "psi_suggestions_results"
  final_dataset_id                 = "${var.project_prefix}_${var.dataset_id}"
  final_bucket_name                = "${var.project_prefix}-${var.bucket_name}"
  gcs_bucket_folder_name           = "config"
  project_prefix                   = "${var.project_prefix}"
  project_id                       = "${var.project_id}"
  countries_ids                    = split(",", "${var.crux_countries}")
}

#######################################
# Configuration Variables
#######################################
variable "bucket_name" {
  type        = string
  description = "Google Cloud Storage Bucket name. The bucket name will be equal to the provided value together with project_prefix"
  default     = "site-speed-dashboard"
}


variable "project_prefix" {
  type        = string
  description = "Prefix that will be used to name the created resources in GCP. For example, we can use the prefix \"br\" for a Brazil client."
  validation {
    condition     = can(regex("[a-z0-9]", var.project_prefix)) && length(var.project_prefix) <= 8
    error_message = "The prefix value must be a [a-z0-9] and size <= 8, exemple \"br01br02\"."
  }
}

variable "dataset_id" {
  type        = string
  description = "Google Cloud BigQuery dataset name."
  default     = "site_speed_dashboard"
}

variable "project_version" {
  type        = string
  description = "Value that represent the current project version. To choose a different version, access https://github.com/DP6/project-name/tags"
  default     = "local"
}

variable "project_id" {
  type        = string
  description = "GCP's project id where project-name module will be installed."
}

variable "region" {
  type        = string
  description = "GCP's project region where all project modules will be created. For more info, access https://cloud.google.com/compute/docs/regions-zones"
  default     = "us-central1"
}

variable "location" {
  type        = string
  description = "GCP's project location. For more info, access https://cloud.google.com/compute/docs/regions-zones"
  default     = "us"
}

variable "service_account_email" {
  type        = string
  description = "Service account that project-name module will use. Required permissions: Storage Object Admin, Cloud Functions Admin, BigQuery Admin e Service Account User"
}

variable "psi_key" {
  type        = string
  description = "PSI API Token. This token is generated at a user level"
}

variable "crux_countries" {
  type        = string
  description = "Countries in which CrUX will be evaluated. The list of countries must be in ISO 3166-1 alpha-2 format (two-letter country code), all lowercase and separated by commas (without spaces in between). If you want to evaluate all countries, use \"all\". If you want to evaluate only one coutry, use only the country code, without commas. Example 1: br,us,fr. Example 2: br. Example 3: all. For a complete table of codes, access https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2"
  validation {
    condition     = can(regex("(all|(^a[^abchjknpvy]|b[^ckpux]|c[^bejpqst]|d[ejkmoz]|e[ceghrst]|f[ijkmor]|g[^cjkovxz]|h[kmnrtu]|i[del-oq-t]|j[emop]|k[eghimnprwyz]|l[abcikr-vy]|m[^bij]|n[acefgiloprUz]|om|p[ae-hk-nrstwy]|qa|r[eosuw]|s[^fpquw]|t[^abeipqsuxy]|u[agmsyz]|v[aceginu]|wf|wf|ye|yt|z[amw]),?)+", var.project_prefix))
    error_message = "The country codes must be on ISO 3166-1 alpha-2 format all lowercase or \"all\"."
  }
}