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
# Cloud Run Jobs Configuration
##################################
resource "google_cloud_run_v2_job" "psi" {
  name     = local.cf_name_psi
  project  = var.project_id
  location = var.region

  template {
    template {
      service_account = var.service_account_email
      max_retries     = 1
      timeout         = "540s"

      containers {
        image = "us-central1-docker.pkg.dev/${var.project_id}/cloud-run-source-deploy/${local.cf_name_psi}:latest"

        env {
          name  = "PROJECT_BUCKET_GCS"
          value = local.bucket_name
        }
        env {
          name  = "PSI_KEY"
          value = var.psi_key
        }
        env {
          name  = "BQ_DATASET_ID"
          value = local.dataset_id
        }

        resources {
          limits = {
            memory = "512Mi"
            cpu    = "1"
          }
        }
      }
    }
  }

  labels = {
    produto = local.project_name
  }
}

resource "google_cloud_run_v2_job_iam_member" "invoker_psi" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_job.psi.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.service_account_email}"
}

resource "google_cloud_run_v2_job" "crux" {
  name     = local.cf_name_crux
  project  = var.project_id
  location = var.region

  template {
    template {
      service_account = var.service_account_email
      max_retries     = 1
      timeout         = "540s"

      containers {
        image = "us-central1-docker.pkg.dev/${var.project_id}/cloud-run-source-deploy/${local.cf_name_crux}:latest"

        env {
          name  = "PROJECT_BUCKET_GCS"
          value = local.bucket_name
        }
        env {
          name  = "PROJECT_DATASET_BQ"
          value = local.dataset_id
        }
        env {
          name  = "PROJECT_NAME"
          value = local.project_id
        }

        resources {
          limits = {
            memory = "256Mi"
            cpu    = "1"
          }
        }
      }
    }
  }

  labels = {
    produto = local.project_name
  }
}

resource "google_cloud_run_v2_job_iam_member" "invoker_crux" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_job.crux.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.service_account_email}"
}



##################################
# Job Scheduler Configuration
##################################
resource "google_cloud_scheduler_job" "scheduler_job_psi" {
  name             = local.scheduler_name_psi
  description      = "PageSpeed Insights Cloud Run Job Trigger"
  schedule         = "0 7 * * *"
  time_zone        = local.scheduler_time_zone
  attempt_deadline = local.scheduler_attempt_deadline

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = "https://run.googleapis.com/v2/projects/${var.project_id}/locations/${var.region}/jobs/${local.cf_name_psi}:run"
    oauth_token {
      service_account_email = var.service_account_email
    }
  }
}

resource "google_cloud_scheduler_job" "scheduler_job_crux" {
  name             = local.scheduler_name_crux
  description      = "CrUX Cloud Run Job Trigger"
  schedule         = "0 17 * * *"
  time_zone        = local.scheduler_time_zone
  attempt_deadline = local.scheduler_attempt_deadline

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = "https://run.googleapis.com/v2/projects/${var.project_id}/locations/${var.region}/jobs/${local.cf_name_crux}:run"
    oauth_token {
      service_account_email = var.service_account_email
    }
  }
}
