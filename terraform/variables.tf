#######################################
#Arquivos de configurações local
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
}

#######################################
#Variaveis de configuração
#######################################
variable "bucket_name" {
  type        = string
  description = "Google Cloud Storage Bucket to create, o valor informado será usado em conjunto com o project_prefix para formar o nome do bucket"
  default     = "site-speed-dashboard"
}


variable "project_prefix" {
  type        = string
  description = "Pré-fixo que será utilizado para nomear os produtos que serão utilizados e criados no GCP, exemplo para o cliente Brasil podemos usar o pré-fixo br"
  validation {
    condition     = can(regex("[a-z0-9]", var.project_prefix)) && length(var.project_prefix) <= 8
    error_message = "The prefix value must be a [a-z0-9] and size <= 8, exemple \"br01br02\"."
  }
}

variable "dataset_id" {
  type        = string
  description = "Google Cloud BigQuery dataset to create recomendado site_speed_dashboard"
  default     = "site_speed_dashboard"
}

variable "project_version" {
  type        = string
  description = "Default versão local parâmetro recebe local, para escolher uma versão diferente da atual acesse https://github.com/DP6/project-name/tags"
  default     = "local"
}

variable "project_id" {
  type        = string
  description = "Id do projeto do GCP onde o modulo project-name será instalado"
}

variable "region" {
  type        = string
  description = "Região do GCP onde os modulos do projeto serão criados https://cloud.google.com/compute/docs/regions-zones?hl=pt-br default us-central1"
  default     = "us-central1"
}

variable "location" {
  type        = string
  description = "Localização do projeto GCP https://cloud.google.com/compute/docs/regions-zones?hl=pt-br default us"
  default     = "us"
}

variable "service_account_email" {
  type        = string
  description = "Service account que será utilizadas pelo modulo project-name, as permissões necessárias são: Storage Object Admin, Cloud Functions Admin, BigQuery Admin e Service Account User"
}

variable "psi_key" {
  type        = string
  description = "Token para utilização da API do PSI com um limite maior de requisições, esse token é gerado á nivel de usuário"
}