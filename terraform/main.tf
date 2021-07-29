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
resource "google_bigquery_dataset" "dataset" {
  location                   = var.location
  dataset_id                 = local.final_dataset_id
  description                = "Descrição do dataset"
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
  depends_on = [google_bigquery_dataset.dataset]
}




##################################
#Configurações Cloud Function
##################################
resource "google_cloudfunctions_function" "function" {
  project               = var.project_id
  name                  = local.cf_name
  description           = "CF project name"
  runtime               = "nodejs14"
  service_account_email = var.service_account_email
  region                = var.region
  available_memory_mb   = 512
  timeout               = 120
  source_archive_bucket = google_storage_bucket.my_storage.name
  source_archive_object = "${local.project_name}/${var.project_version}.zip"
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

