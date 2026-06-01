# Migração para Cloud Run Functions 2ª gen — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrar as Cloud Functions de PSI (Node.js) e CrUX (Python) da 1ª geração para Cloud Run Functions 2ª geração.

**Architecture:** Mesma arquitetura atual — duas funções HTTP disparadas por Cloud Scheduler — mas usando o resource `google_cloudfunctions2_function` no Terraform, IAM via `google_cloud_run_service_iam_member` e `roles/run.invoker`, e o `functions-framework` explícito no CrUX Python.

**Tech Stack:** Terraform (google provider ≥ 5.0), Node.js 20, Python 3.12, `functions-framework` 3.x

---

## Arquivos modificados

| Arquivo | Ação |
|---------|------|
| `functions/crux/requirements.txt` | Adicionar `functions-framework>=3.0.0` |
| `functions/crux/main.py` | Adicionar `@functions_framework.http` e renomear parâmetro |
| `terraform/provider.tf` | Adicionar bloco `required_providers` com versão mínima |
| `terraform/main.tf` | Trocar `google_cloudfunctions_function` por `google_cloudfunctions2_function` e atualizar IAM e Scheduler |

---

## Task 1: Atualizar função CrUX (Python) para 2ª gen

**Files:**
- Modify: `functions/crux/requirements.txt`
- Modify: `functions/crux/main.py`

- [ ] **Step 1: Adicionar `functions-framework` ao requirements.txt**

Substituir o conteúdo de `functions/crux/requirements.txt` por:

```txt
# Function dependencies, for example:
# package>=version
google-cloud-bigquery>=2.20.0
google-cloud-storage>=1.40.0
google-cloud>=0.34.0
functions-framework>=3.0.0
```

- [ ] **Step 2: Atualizar `main.py` com decorator e assinatura correta**

Substituir o conteúdo de `functions/crux/main.py` por:

```python
import functions_framework
from google.cloud import bigquery
from google.cloud import storage
from util_class import Crux
import logging
import os

logging.basicConfig(level=logging.INFO)

storage_client = storage.Client()
bigquery_client = bigquery.Client()

project = os.environ.get('PROJECT_NAME')
dataset = os.environ.get('PROJECT_DATASET_BQ')

crux_table = "{project}.{dataset}.crux_table".format(project=project, dataset=dataset)
crux = Crux(bigquery_client, crux_table, bigquery, storage_client)


@functions_framework.http
def main(request):

    log = ""
    if(crux.check_last_month()):
        log = "Previously updated CRUX table."
    else:

        if(crux.check_table_crux()):
            response = crux.update_crux_table()
            if(response == True):
                log = "CRUX table updated successfully."
        else:
            log = "CRUX table not available."

    logging.info(log)
    return log
```

- [ ] **Step 3: Commit**

```bash
git add functions/crux/requirements.txt functions/crux/main.py
git commit -m "feat: update CrUX function for Cloud Run Functions 2nd gen"
```

---

## Task 2: Atualizar Terraform — provider

**Files:**
- Modify: `terraform/provider.tf`

- [ ] **Step 1: Adicionar versão mínima do provider**

Substituir o conteúdo de `terraform/provider.tf` por:

```hcl
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
```

- [ ] **Step 2: Commit**

```bash
git add terraform/provider.tf
git commit -m "feat: set minimum google provider version for Cloud Run Functions 2nd gen"
```

---

## Task 3: Atualizar Terraform — Cloud Run Functions 2ª gen

**Files:**
- Modify: `terraform/main.tf`

- [ ] **Step 1: Substituir a Cloud Function PSI (1ª gen) pela 2ª gen**

No `terraform/main.tf`, substituir o bloco `resource "google_cloudfunctions_function" "psi"` e `resource "google_cloudfunctions_function_iam_member" "invoker_psi"` por:

```hcl
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
```

- [ ] **Step 2: Substituir a Cloud Function CrUX (1ª gen) pela 2ª gen**

No `terraform/main.tf`, substituir o bloco `resource "google_cloudfunctions_function" "crux"` e `resource "google_cloudfunctions_function_iam_member" "invoker_crux"` por:

```hcl
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
```

- [ ] **Step 3: Atualizar o Cloud Scheduler PSI para usar a URI da função 2ª gen**

No bloco `resource "google_cloud_scheduler_job" "scheduler_job_psi"`, substituir o `http_target` por:

```hcl
  http_target {
    http_method = "GET"
    uri         = google_cloudfunctions2_function.psi.service_config[0].uri
    oidc_token {
      service_account_email = var.service_account_email
    }
  }
```

- [ ] **Step 4: Atualizar o Cloud Scheduler CrUX para usar a URI da função 2ª gen**

No bloco `resource "google_cloud_scheduler_job" "scheduler_job_crux"`, substituir o `http_target` por:

```hcl
  http_target {
    http_method = "GET"
    uri         = google_cloudfunctions2_function.crux.service_config[0].uri
    oidc_token {
      service_account_email = var.service_account_email
    }
  }
```

- [ ] **Step 5: Commit**

```bash
git add terraform/main.tf
git commit -m "feat: migrate PSI and CrUX to Cloud Run Functions 2nd gen"
```

---

## Task 4: Validar o Terraform

- [ ] **Step 1: Inicializar o Terraform (necessário após mudança de provider)**

```bash
cd terraform && terraform init -upgrade
```

Esperado: `Terraform has been successfully initialized!`

- [ ] **Step 2: Validar a sintaxe**

```bash
terraform validate
```

Esperado: `Success! The configuration is valid.`

- [ ] **Step 3: Revisar o plan antes de aplicar**

```bash
terraform plan
```

Verificar que o plan mostra:
- Destruição dos resources `google_cloudfunctions_function` (1ª gen)
- Criação dos resources `google_cloudfunctions2_function` (2ª gen)
- Atualização dos `google_cloud_scheduler_job` com novas URIs

- [ ] **Step 4: Commit de validação (se terraform plan OK)**

```bash
cd ..
git add .
git commit -m "chore: confirm terraform validates for Cloud Run Functions 2nd gen migration"
```

---

## Permissões adicionais necessárias para o deploy

Além das permissões já listadas, para Cloud Run Functions 2ª gen são necessárias:

| Role | Motivo |
|------|--------|
| `roles/run.developer` | Gerenciar os serviços Cloud Run criados pela 2ª gen |
| `roles/artifactregistry.writer` | A 2ª gen armazena as imagens no Artifact Registry |

APIs adicionais a ativar:
```bash
gcloud services enable run.googleapis.com artifactregistry.googleapis.com
```
