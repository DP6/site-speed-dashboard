######################################################
# Cloud Storage Configuration
######################################################
resource "google_storage_bucket" "my_storage" {
  name          = local.bucket_name
  location      = var.location
  force_destroy = true

  labels = {
    produto = local.project_name
  }
}

resource "local_file" "config_json" { 
  content = templatefile("./config_template.tftpl", { dataset = local.project_prefix, lista = local.countries_ids }) 
  filename = "./files-copy-to-gcs/config/config.json"
}

resource "null_resource" "cf_code_zip" {
  triggers = {
    on_version_change = var.project_version
  }

  provisioner "local-exec" {
    command = "sh scripts/create_and_send_zips.sh ${var.project_version} ${local.bucket_name}"
  }

  depends_on = [google_storage_bucket.my_storage]
}

######################################################
# BigQuery Configuration
######################################################
#dataset
resource "google_bigquery_dataset" "site_speed_dashboard" {
  location                   = var.location
  dataset_id                 = local.dataset_id
  description                = "Site Speed Dashboard Dataset"
  delete_contents_on_destroy = true

  labels = {
    produto = local.project_name
  }
}

resource "google_bigquery_table" "psi_metrics_results" {
  dataset_id          = local.dataset_id
  table_id            = local.bq_table_psi_metrics_results
  description         = "Table with PageSpeed Insights collected metrics"
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
  dataset_id          = local.dataset_id
  table_id            = local.bq_table_crux_table
  description         = "Table with CrUX collected metrics"
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
  dataset_id          = local.dataset_id
  table_id            = local.bq_table_psi_suggestions_results
  description         = "Table with PageSpeed Insights collected Suggestions"
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
# Cloud Function Configuration
##################################
resource "google_cloudfunctions2_function" "psi" {
  name        = local.cf_name_psi
  location    = var.region
  description = "Execution of PageSpeed Insights API to collect performance metrics"

  build_config {
    runtime     = "nodejs20"
    entry_point = local.cf_entry_point_psi
    source {
      storage_source {
        bucket = google_storage_bucket.my_storage.name
        object = "${local.gcs_bucket_folder_name}/psi.zip"
      }
    }
  }

  service_config {
    max_instance_count    = 1
    available_memory      = "512Mi"
    timeout_seconds       = 540
    service_account_email = var.service_account_email
    environment_variables = {
      PROJECT_BUCKET_GCS = local.bucket_name
      PSI_KEY            = var.psi_key
      BQ_DATASET_ID      = local.dataset_id
    }
  }

  labels = {
    produto = local.project_name
  }

  depends_on = [null_resource.cf_code_zip]
}

resource "google_cloud_run_service_iam_member" "invoker_psi" {
  project  = var.project_id
  location = google_cloudfunctions2_function.psi.location
  service  = google_cloudfunctions2_function.psi.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.service_account_email}"
}

resource "google_cloudfunctions2_function" "crux" {
  name        = local.cf_name_crux
  location    = var.region
  description = "Execution of CrUX API to collect performance metrics"

  build_config {
    runtime     = "python312"
    entry_point = local.cf_entry_point_crux
    source {
      storage_source {
        bucket = google_storage_bucket.my_storage.name
        object = "${local.gcs_bucket_folder_name}/crux.zip"
      }
    }
  }

  service_config {
    max_instance_count    = 1
    available_memory      = "256Mi"
    timeout_seconds       = 120
    service_account_email = var.service_account_email
    environment_variables = {
      PROJECT_BUCKET_GCS = local.bucket_name
      PROJECT_DATASET_BQ = local.dataset_id
      PROJECT_NAME       = local.project_id
    }
  }

  labels = {
    produto = local.project_name
  }

  depends_on = [null_resource.cf_code_zip]
}

resource "google_cloud_run_service_iam_member" "invoker_crux" {
  project  = var.project_id
  location = google_cloudfunctions2_function.crux.location
  service  = google_cloudfunctions2_function.crux.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.service_account_email}"
}



##################################
# Job Scheduler Configuration
##################################
resource "google_cloud_scheduler_job" "scheduler_job_psi" {
  name             = local.scheduler_name_psi
  description      = "PageSpeed Insights API HTTP Trigger"
  schedule         = "0 7 * * *"
  time_zone        = local.scheduler_time_zone
  attempt_deadline = local.scheduler_attempt_deadline
  
  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "GET"
    uri         = google_cloudfunctions2_function.psi.service_config[0].uri
    oidc_token {
      service_account_email = var.service_account_email
    }
  }
}

resource "google_cloud_scheduler_job" "scheduler_job_crux" {
  name             = local.scheduler_name_crux
  description      = "CrUX API HTTP Trigger"
  schedule         = "0 17 * * *"
  time_zone        = local.scheduler_time_zone
  attempt_deadline = local.scheduler_attempt_deadline

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "GET"
    uri         = google_cloudfunctions2_function.crux.service_config[0].uri
    oidc_token {
      service_account_email = var.service_account_email
    }
  }
}
