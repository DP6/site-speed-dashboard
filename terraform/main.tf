######################################################
#Configurações Cloud Storage
######################################################
resource "google_storage_bucket" "my_storage" {
  name          = local.final_bucket_name
  location      = var.location
  force_destroy = true

  labels = {
    produto = local.project_name
  }
}

resource "null_resource" "cf_code_zip" {
  triggers = {
    on_version_change = var.project_version
  }

  provisioner "local-exec" {
    command = "sh scripts/${var.project_version != "local" ? "download-project.sh" : "using-local-project.sh"} ${var.project_version} ${local.final_bucket_name}"
  }

  depends_on = [google_storage_bucket.my_storage]
}

######################################################
#Configurações bigquery
######################################################
#dataset
resource "google_bigquery_dataset" "site_speed_dashboard" {
  location                   = var.location
  dataset_id                 = local.final_dataset_id
  description                = "Site Speed Dashboard Dataset"
  delete_contents_on_destroy = true

  labels = {
    produto = local.project_name
  }
}

resource "google_bigquery_table" "psi_metrics_results" {
  dataset_id          = local.final_dataset_id
  table_id            = local.bq_table_psi_metrics_results
  description         = "Tabela com métricas coletadas do PageSpeed Insights"
  schema              = file("bigquery/psi_metrics_results.json")
  clustering          = ["data"]
  expiration_time     = null
  deletion_protection = false
  time_partitioning {
    type                     = "DAY"
    field                    = "data"
    require_partition_filter = false
    expiration_ms            = null
  }
  labels = {
    produto = local.project_name
  }
  depends_on = [google_bigquery_dataset.site_speed_dashboard]
}

resource "google_bigquery_table" "crux_table" {
  dataset_id          = local.final_dataset_id
  table_id            = local.bq_table_crux_table
  description         = "Tabela com métricas coletadas do CrUX"
  schema              = file("bigquery/crux_table.json")
  clustering          = ["data"]
  expiration_time     = null
  deletion_protection = false
  time_partitioning {
    type                     = "DAY"
    field                    = "data"
    require_partition_filter = false
    expiration_ms            = null
  }
  labels = {
    produto = local.project_name
  }
  depends_on = [google_bigquery_dataset.site_speed_dashboard]
}

resource "google_bigquery_table" "psi_suggestions_results" {
  dataset_id          = local.final_dataset_id
  table_id            = local.bq_table_psi_suggestions_results
  description         = "Tabela com sugestões coletadas do PageSpeed Insights"
  schema              = file("bigquery/psi_suggestions_results.json")
  clustering          = ["data"]
  expiration_time     = null
  deletion_protection = false
  time_partitioning {
    type                     = "DAY"
    field                    = "data"
    require_partition_filter = false
    expiration_ms            = null
  }
  labels = {
    produto = local.project_name
  }
  depends_on = [google_bigquery_dataset.site_speed_dashboard]
}



##################################
#Configurações Cloud Function
##################################
resource "google_cloudfunctions_function" "function" {
  project               = var.project_id
  name                  = local.cf_name
  description           = "Execução do PageSpeed Insights para coleta de métricas de performance"
  runtime               = "nodejs14"
  service_account_email = var.service_account_email
  region                = var.region
  available_memory_mb   = 512
  timeout               = 540
  source_archive_bucket = google_storage_bucket.my_storage.name
  source_archive_object = "${local.gcs_bucket_folder_name}/${var.project_version}.zip"
  trigger_http          = true
  entry_point           = local.cf_entry_point
  environment_variables = {
    PROJECT_BUCKET_GCS = local.final_bucket_name
  }
  depends_on = [null_resource.cf_code_zip]
}


# IAM entry for all users to invoke the function
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = var.project_id
  region         = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

resource "google_cloudfunctions_function" "crux_data" {
  project               = var.project_id
  name                  = "crux_data"
  description           = "Cole de métricas de performance do CrUX"
  runtime               = "python39"
  service_account_email = var.service_account_email
  region                = var.region
  available_memory_mb   = 256
  timeout               = 120
  source_archive_bucket = google_storage_bucket.my_storage.name
  source_archive_object = "${local.gcs_bucket_folder_name}/crux_data.zip"
  trigger_http          = true
  entry_point           = "main"
  environment_variables = {
    PROJECT_BUCKET_GCS = local.final_bucket_name
  }
  depends_on = [null_resource.cf_code_zip]
}



# IAM entry for all users to invoke the function
resource "google_cloudfunctions_function_iam_member" "invoker_crux" {
  project        = var.project_id
  region         = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.crux_data.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}



##################################
#Configurações do Job Scheduler
##################################
resource "google_cloud_scheduler_job" "job" {
  name             = "site-speed-dashboard-schedule"
  description      = "test http job"
  schedule         = "0 7 * * *"
  time_zone        = "America/Sao_Paulo"
  attempt_deadline = "320s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "GET"
    uri         = "https://${google_cloudfunctions_function.function.region}-${var.project_id}.cloudfunctions.net/${local.cf_name}"
  }
}

resource "google_cloud_scheduler_job" "job_crux" {
  name             = "site-speed-dashboard-schedule"
  description      = "test http job"
  schedule         = "0 17 * * *"
  time_zone        = "America/Sao_Paulo"
  attempt_deadline = "320s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "GET"
    uri         = "https://${google_cloudfunctions_function.function.region}-${var.project_id}.cloudfunctions.net/crux_data"
  }
}