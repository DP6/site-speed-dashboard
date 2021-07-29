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

resource "google_bigquery_table" "project-name-raw" {
  dataset_id          = local.final_dataset_id
  table_id            = local.bq_table_id_raw
  description         = "Descrição da tabela"
  schema              = file("bigquery/schema_project_name_raw.json")
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

resource "google_bigquery_table" "project-name-aggregation" {
  dataset_id          = local.final_dataset_id
  table_id            = local.bq_table_id_aggregation
  description         = "Descrição da tabela de consolidação"
  schema              = file("bigquery/schema_project_name_aggregation.json")
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

data "template_file" "view_aggregation" {
  template = file("bigquery/query_view_aggregation.sql")
  vars = {
    table_name = "${var.project_id}.${local.final_dataset_id}.${local.bq_table_id_raw}"
  }
}

resource "google_bigquery_table" "view_aggregation" {
  dataset_id          = local.final_dataset_id
  table_id            = local.bq_view_aggregation
  description         = "View com os dados agregados da tabela ${local.bq_table_id_raw}"
  deletion_protection = false
  view {
    query          = data.template_file.view_aggregation.rendered
    use_legacy_sql = false
  }
  labels = {
    produto = local.project_name
  }
  depends_on = [google_bigquery_dataset.dataset, google_bigquery_table.project-name-raw]
}

resource "google_bigquery_data_transfer_config" "query_config_aggregation" {
  depends_on = [google_bigquery_table.project-name-aggregation]

  display_name           = "consolidate_view_aggregation"
  location               = var.location
  data_source_id         = "scheduled_query"
  schedule               = "every day 07:00"
  destination_dataset_id = google_bigquery_table.project-name-aggregation.dataset_id
  params = {
    destination_table_name_template = local.bq_table_id_aggregation
    write_disposition               = "WRITE_APPEND"
    query                           = "SELECT * FROM ${var.project_id}.${local.final_dataset_id}.${local.bq_view_aggregation}"
  }
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

