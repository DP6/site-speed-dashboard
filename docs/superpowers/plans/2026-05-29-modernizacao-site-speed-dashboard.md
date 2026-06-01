# Site Speed Dashboard — Plano de Modernização

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Atualizar o projeto Site Speed Dashboard para funcionar com os runtimes atuais do GCP, as Core Web Vitals de 2024 (INP em vez de FID) e corrigir vulnerabilidades de segurança no IAM.

**Architecture:** O projeto tem duas Cloud Functions independentes (PSI em Node.js e CrUX em Python) provisionadas via Terraform, com schemas de tabela no BigQuery. As mudanças seguem a ordem: código → schema → testes → infra, para que cada etapa possa ser validada antes de avançar.

**Tech Stack:** Node.js 20, Python 3.12, Terraform, Google Cloud Functions Gen 1→2, BigQuery, Google PageSpeed Insights API v5, CrUX BigQuery Public Dataset.

---

## Arquivos modificados

| Arquivo | O que muda |
|---|---|
| `terraform/main.tf` | Runtimes (nodejs14→nodejs20, python39→python312), IAM (allUsers→service account), migração gen 2 |
| `functions/psi/index.js` | Remover FMP/FCPUIdle/InputLatency, adicionar INP, atualizar loadingExperience |
| `terraform/bigquery/psi_metrics_results.json` | Remover campos obsoletos, adicionar Lab_INP e Loading_INP |
| `functions/psi/test/unit/index.test.js` | Atualizar asserts para refletir novos campos |
| `functions/crux/util_query.py` | Substituir FID por INP, corrigir TTFB, atualizar base_final e thresholds |
| `terraform/bigquery/crux_table.json` | Substituir fid_density/good_fid/poor_fid/average_fid por campos INP |

---

## Task 1: Atualizar runtimes no Terraform

**Files:**
- Modify: `terraform/main.tf:112` (runtime PSI)
- Modify: `terraform/main.tf:144` (runtime CrUX)

- [ ] **Step 1: Alterar runtime da Cloud Function PSI**

Em `terraform/main.tf`, linha 112, trocar:
```hcl
runtime = "nodejs14"
```
Por:
```hcl
runtime = "nodejs20"
```

- [ ] **Step 2: Alterar runtime da Cloud Function CrUX**

Em `terraform/main.tf`, linha 144, trocar:
```hcl
runtime = "python39"
```
Por:
```hcl
runtime = "python312"
```

- [ ] **Step 3: Validar sintaxe Terraform**

```bash
cd terraform
terraform fmt
terraform validate
```
Expected: `Success! The configuration is valid.`

- [ ] **Step 4: Commit**

```bash
git add terraform/main.tf
git commit -m "fix: update Cloud Functions runtimes to nodejs20 and python312"
```

---

## Task 2: Remover métricas depreciadas do PSI e adicionar INP

**Files:**
- Modify: `functions/psi/index.js`

As métricas `FMP`, `FCPUIdle`, `first-cpu-idle`, `max-potential-fid` e `estimated-input-latency` foram removidas do Lighthouse v9+. O FID (`max-potential-fid`) foi substituído pelo INP (`interaction-to-next-paint`) como Core Web Vital.

- [ ] **Step 1: Remover variável `fid` global e métricas obsoletas de `_formatLightHouseResult`**

Substituir toda a função `_formatLightHouseResult` (linhas 83–104) por:

```js
function _formatLightHouseResult(date, brand, page, URL, lighthouseResult) {
  return {
    Data: date,
    Brand: brand,
    Page: page,
    Site: URL,
    Device: lighthouseResult.configSettings.emulatedFormFactor,
    Score: lighthouseResult.categories.performance.score,
    LAB_FCP: lighthouseResult.audits['first-contentful-paint']?.numericValue || null,
    LAB_SpeedIndex: lighthouseResult.audits['speed-index']?.numericValue || null,
    LAB_TTI: lighthouseResult.audits['interactive']?.numericValue || null,
    LAB_TTFB: lighthouseResult.audits['server-response-time']?.numericValue || null,
    LAB_RenderBlocking: lighthouseResult.audits['render-blocking-resources']?.numericValue || null,
    LAB_TBT: lighthouseResult.audits['total-blocking-time']?.numericValue || null,
    LAB_CLS: lighthouseResult.audits['cumulative-layout-shift']?.numericValue || null,
    LAB_LCP: lighthouseResult.audits['largest-contentful-paint']?.numericValue || null,
    LAB_INP: lighthouseResult.audits['interaction-to-next-paint']?.numericValue || null,
  };
}
```

Também remover a declaração `let fid;` na linha 9.

- [ ] **Step 2: Atualizar `_formatLoadingResult` — substituir FID por INP**

Substituir toda a função `_formatLoadingResult` (linhas 113–135) por:

```js
function _formatLoadingResult({ metrics, overall_category }) {
  const mock = {
    CUMULATIVE_LAYOUT_SHIFT_SCORE: { category: null, percentile: null },
    FIRST_CONTENTFUL_PAINT_MS: { category: null, percentile: null },
    INTERACTION_TO_NEXT_PAINT: { category: null, percentile: null },
    LARGEST_CONTENTFUL_PAINT_MS: { category: null, percentile: null },
  };
  let { CUMULATIVE_LAYOUT_SHIFT_SCORE, FIRST_CONTENTFUL_PAINT_MS, INTERACTION_TO_NEXT_PAINT, LARGEST_CONTENTFUL_PAINT_MS } =
    metrics || mock;

  return {
    Loading_CLS_Category: CUMULATIVE_LAYOUT_SHIFT_SCORE?.category || null,
    Loading_CLS: CUMULATIVE_LAYOUT_SHIFT_SCORE?.percentile || null,
    Loading_FCP_Category: FIRST_CONTENTFUL_PAINT_MS?.category || null,
    Loading_FCP: FIRST_CONTENTFUL_PAINT_MS?.percentile || null,
    Loading_INP_Category: INTERACTION_TO_NEXT_PAINT?.category || null,
    Loading_INP: INTERACTION_TO_NEXT_PAINT?.percentile || null,
    Loading_LCP_Category: LARGEST_CONTENTFUL_PAINT_MS?.category || null,
    Loading_LCP: LARGEST_CONTENTFUL_PAINT_MS?.percentile || null,
    Loading_Overall_Category: overall_category || null,
  };
}
```

- [ ] **Step 3: Verificar que não restam referências a campos removidos**

```bash
grep -n "FMP\|FCPUIdle\|InputLatency\|max-potential-fid\|first-cpu-idle\|estimated-input-latency\|FIRST_INPUT_DELAY\|LAB_FID\|Loading_FID" functions/psi/index.js
```
Expected: nenhuma saída.

- [ ] **Step 4: Commit**

```bash
git add functions/psi/index.js
git commit -m "feat: remove deprecated Lighthouse metrics and add INP support to PSI function"
```

---

## Task 3: Atualizar schema BigQuery da tabela PSI

**Files:**
- Modify: `terraform/bigquery/psi_metrics_results.json`

Remover os campos `Lab_FMP`, `Lab_FCPUIdle`, `Lab_InputLatency`, `Lab_FID`, `Loading_FID_Category`, `Loading_FID`. Adicionar `Lab_INP`, `Loading_INP_Category`, `Loading_INP`.

- [ ] **Step 1: Reescrever o schema**

Substituir o conteúdo de `terraform/bigquery/psi_metrics_results.json` por:

```json
[
  { "mode": "NULLABLE", "name": "Data", "type": "DATE" },
  { "mode": "NULLABLE", "name": "Brand", "type": "STRING" },
  { "mode": "NULLABLE", "name": "Page", "type": "STRING" },
  { "mode": "NULLABLE", "name": "Site", "type": "STRING" },
  { "mode": "NULLABLE", "name": "Device", "type": "STRING" },
  { "mode": "NULLABLE", "name": "Score", "type": "FLOAT" },
  { "mode": "NULLABLE", "name": "Lab_FCP", "type": "FLOAT" },
  { "mode": "NULLABLE", "name": "Lab_SpeedIndex", "type": "FLOAT" },
  { "mode": "NULLABLE", "name": "Lab_TTI", "type": "FLOAT" },
  { "mode": "NULLABLE", "name": "Lab_TTFB", "type": "FLOAT" },
  { "mode": "NULLABLE", "name": "Lab_RenderBlocking", "type": "FLOAT" },
  { "mode": "NULLABLE", "name": "Lab_TBT", "type": "FLOAT" },
  { "mode": "NULLABLE", "name": "Lab_CLS", "type": "FLOAT" },
  { "mode": "NULLABLE", "name": "Lab_LCP", "type": "FLOAT" },
  { "mode": "NULLABLE", "name": "Lab_INP", "type": "FLOAT" },
  { "mode": "NULLABLE", "name": "Loading_CLS_Category", "type": "STRING" },
  { "mode": "NULLABLE", "name": "Loading_CLS", "type": "STRING" },
  { "mode": "NULLABLE", "name": "Loading_FCP_Category", "type": "STRING" },
  { "mode": "NULLABLE", "name": "Loading_FCP", "type": "STRING" },
  { "mode": "NULLABLE", "name": "Loading_INP_Category", "type": "STRING" },
  { "mode": "NULLABLE", "name": "Loading_INP", "type": "STRING" },
  { "mode": "NULLABLE", "name": "Loading_LCP_Category", "type": "STRING" },
  { "mode": "NULLABLE", "name": "Loading_LCP", "type": "STRING" },
  { "mode": "NULLABLE", "name": "Loading_Overall_Category", "type": "STRING" }
]
```

- [ ] **Step 2: Validar Terraform**

```bash
cd terraform
terraform validate
```
Expected: `Success! The configuration is valid.`

- [ ] **Step 3: Commit**

```bash
git add terraform/bigquery/psi_metrics_results.json
git commit -m "feat: update PSI BigQuery schema — remove deprecated fields, add INP"
```

---

## Task 4: Atualizar testes unitários do PSI

**Files:**
- Modify: `functions/psi/test/unit/index.test.js`

> **Nota:** Os testes de integração requerem conexão real com o GCS. Para rodar localmente, é necessário `gcloud auth application-default login` e um bucket `site_speed_dashboard_test` acessível. Os testes unitários de `#getUrls()` não precisam de GCS.

- [ ] **Step 1: Atualizar assertions de `#getUrlsDesktop()` e `#getUrlsMobile()`**

Nas duas funções de teste (linhas 67–121), substituir o bloco de `expect` por:

```js
expect(response.speedResults[0]).to.have.own.property('Data');
expect(response.speedResults[0]).to.have.own.property('Brand');
expect(response.speedResults[0]).to.have.own.property('Page');
expect(response.speedResults[0]).to.have.own.property('Site');
expect(response.speedResults[0]).to.have.own.property('Device');
expect(response.speedResults[0]).to.have.own.property('Score');
expect(response.speedResults[0]).to.have.own.property('LAB_FCP');
expect(response.speedResults[0]).to.have.own.property('LAB_SpeedIndex');
expect(response.speedResults[0]).to.have.own.property('LAB_TTI');
expect(response.speedResults[0]).to.have.own.property('LAB_TTFB');
expect(response.speedResults[0]).to.have.own.property('LAB_RenderBlocking');
expect(response.speedResults[0]).to.have.own.property('LAB_TBT');
expect(response.speedResults[0]).to.have.own.property('LAB_CLS');
expect(response.speedResults[0]).to.have.own.property('LAB_LCP');
expect(response.speedResults[0]).to.have.own.property('LAB_INP');
```

Aplicar o mesmo bloco nas seções `#getUrlsDesktop()` e `#getUrlsMobile()`.

- [ ] **Step 2: Verificar que não restam referências a campos removidos nos testes**

```bash
grep -n "LAB_FMP\|LAB_FCPUIdle\|LAB_InputLatency\|LAB_FID" functions/psi/test/unit/index.test.js
```
Expected: nenhuma saída.

- [ ] **Step 3: Rodar apenas os testes unitários que não precisam de GCS**

```bash
cd functions/psi
npm run unit-test -- --grep "#getUrls()"
```
Expected: 2 passing.

- [ ] **Step 4: Commit**

```bash
git add functions/psi/test/unit/index.test.js
git commit -m "test: update PSI unit tests to reflect new metrics (INP, remove deprecated)"
```

---

## Task 5: Atualizar query CrUX — substituir FID por INP

**Files:**
- Modify: `functions/crux/util_query.py`

O FID (`first_input.delay`) foi substituído pelo INP (`interaction_to_next_paint`) no dataset CrUX. Os thresholds do INP são: bom < 200ms, needs improvement 200–500ms, poor > 500ms.

- [ ] **Step 1: Substituir o CTE `fid` pelo CTE `inp`**

No arquivo `functions/crux/util_query.py`, localizar o bloco:
```python
        fid AS 
        (          --- FID
            SELECT 
                year_month,
                origin, 
                bin.start start,
                bin.end ended,
                effective_connection_type.name AS connection,
                form_factor.name AS form,
                sum(bin.density) density
            FROM base_crux 
                LEFT JOIN UNNEST(first_input.delay.histogram.bin) AS bin
            GROUP BY 1,2,3,4,5,6
            ORDER BY start
        ),
```

Substituir por:
```python
        inp AS 
        (          --- INP
            SELECT 
                year_month,
                origin, 
                bin.start start,
                bin.end ended,
                effective_connection_type.name AS connection,
                form_factor.name AS form,
                sum(bin.density) density
            FROM base_crux 
                LEFT JOIN UNNEST(interaction_to_next_paint.histogram.bin) AS bin
            GROUP BY 1,2,3,4,5,6
            ORDER BY start
        ),
```

- [ ] **Step 2: Atualizar `base_final` — substituir fid por inp**

Localizar no bloco `base_final`:
```sql
COALESCE(lcp.year_month,fcp.year_month,dcl.year_month,onload.year_month,fp.year_month,fid.year_month,ttfb.year_month,cls.year_month ) AS year_month,
COALESCE(lcp.start,fcp.start,dcl.start,onload.start,fp.start,fid.start,ttfb.start,cls.start) AS start,
COALESCE(lcp.ended,fcp.ended,dcl.ended,onload.ended,fp.ended,fid.ended,ttfb.ended,cls.ended) AS ended,
COALESCE(lcp.form,fcp.form,dcl.form,onload.form,fp.form,fid.form,ttfb.form,cls.form) AS form,
COALESCE(lcp.origin,fcp.origin,dcl.origin,onload.origin,fp.origin,fid.origin,ttfb.origin,cls.origin) AS origin,
COALESCE(lcp.connection,fcp.connection,dcl.connection,onload.connection,fp.connection,fid.connection,ttfb.connection,cls.connection) AS connection,
```

Substituir por:
```sql
COALESCE(lcp.year_month,fcp.year_month,dcl.year_month,onload.year_month,fp.year_month,inp.year_month,ttfb.year_month,cls.year_month ) AS year_month,
COALESCE(lcp.start,fcp.start,dcl.start,onload.start,fp.start,inp.start,ttfb.start,cls.start) AS start,
COALESCE(lcp.ended,fcp.ended,dcl.ended,onload.ended,fp.ended,inp.ended,ttfb.ended,cls.ended) AS ended,
COALESCE(lcp.form,fcp.form,dcl.form,onload.form,fp.form,inp.form,ttfb.form,cls.form) AS form,
COALESCE(lcp.origin,fcp.origin,dcl.origin,onload.origin,fp.origin,inp.origin,ttfb.origin,cls.origin) AS origin,
COALESCE(lcp.connection,fcp.connection,dcl.connection,onload.connection,fp.connection,inp.connection,ttfb.connection,cls.connection) AS connection,
```

- [ ] **Step 3: Atualizar a linha `fid_density` em `base_final`**

Localizar:
```sql
COALESCE(fid.density,0) fid_density,
```
Substituir por:
```sql
COALESCE(inp.density,0) inp_density,
```

- [ ] **Step 4: Atualizar o JOIN em `base_final`**

Localizar:
```sql
FULL OUTER JOIN fid using(year_month,start,form,origin,connection,ended)
```
Substituir por:
```sql
FULL OUTER JOIN inp using(year_month,start,form,origin,connection,ended)
```

- [ ] **Step 5: Atualizar o bloco `thresholds`**

Localizar:
```sql
STRUCT("FID"  AS metric, 100  AS min, 300  AS max),
```
Substituir por:
```sql
STRUCT("INP"  AS metric, 200  AS min, 500  AS max),
```

- [ ] **Step 6: Atualizar o SELECT final — substituir blocos fid por inp**

Localizar:
```sql
IF(start <  (SELECT min from UNNEST(limits) WHERE metric = "FID") ,fid_density,0) AS good_fid,
IF(start >= (SELECT max from UNNEST(limits) WHERE metric = "FID") ,fid_density,0) AS poor_fid,
IF(start >= (SELECT min from UNNEST(limits) WHERE metric = "FID") and start < (SELECT max from UNNEST(limits) WHERE metric = "FID") ,fid_density,0) AS average_fid,
```
Substituir por:
```sql
IF(start <  (SELECT min from UNNEST(limits) WHERE metric = "INP") ,inp_density,0) AS good_inp,
IF(start >= (SELECT max from UNNEST(limits) WHERE metric = "INP") ,inp_density,0) AS poor_inp,
IF(start >= (SELECT min from UNNEST(limits) WHERE metric = "INP") and start < (SELECT max from UNNEST(limits) WHERE metric = "INP") ,inp_density,0) AS average_inp,
```

- [ ] **Step 7: Verificar que não restam referências a fid**

```bash
grep -n "fid" functions/crux/util_query.py
```
Expected: nenhuma saída.

- [ ] **Step 8: Commit**

```bash
git add functions/crux/util_query.py
git commit -m "feat: replace FID with INP in CrUX query (Core Web Vitals 2024)"
```

---

## Task 6: Atualizar schema BigQuery da tabela CrUX

**Files:**
- Modify: `terraform/bigquery/crux_table.json`

- [ ] **Step 1: Substituir campos fid por inp**

No arquivo `terraform/bigquery/crux_table.json`, localizar e substituir o bloco:
```json
  { "name": "fid_density", "type": "FLOAT" },
```
Por:
```json
  { "name": "inp_density", "type": "FLOAT" },
```

Depois localizar:
```json
  { "name": "good_fid", "type": "FLOAT" },
  { "name": "poor_fid", "type": "FLOAT" },
  { "name": "average_fid", "type": "FLOAT" },
```
Substituir por:
```json
  { "name": "good_inp", "type": "FLOAT" },
  { "name": "poor_inp", "type": "FLOAT" },
  { "name": "average_inp", "type": "FLOAT" },
```

- [ ] **Step 2: Validar Terraform**

```bash
cd terraform
terraform validate
```
Expected: `Success! The configuration is valid.`

- [ ] **Step 3: Commit**

```bash
git add terraform/bigquery/crux_table.json
git commit -m "feat: update CrUX BigQuery schema — replace FID with INP"
```

---

## Task 7: Corrigir IAM — remover acesso público às Cloud Functions

**Files:**
- Modify: `terraform/main.tf`

Atualmente ambas as functions têm `member = "allUsers"`, ficando abertas na internet sem autenticação. O Cloud Scheduler precisa de uma identidade para invocar as functions via OIDC.

> **Pré-requisito:** O `var.service_account_email` (já declarado em `variables.tf`) deve ser a mesma service account usada pelo Cloud Scheduler ou ter permissão `iam.serviceAccounts.actAs`.

- [ ] **Step 1: Remover os dois blocos `google_cloudfunctions_function_iam_member` com `allUsers`**

Em `terraform/main.tf`, remover completamente os dois recursos:
```hcl
resource "google_cloudfunctions_function_iam_member" "invoker" {
  ...
  member = "allUsers"
}

resource "google_cloudfunctions_function_iam_member" "invoker_crux" {
  ...
  member = "allUsers"
}
```

Substituir por um único bloco que concede acesso apenas à service account:
```hcl
resource "google_cloudfunctions_function_iam_member" "invoker_psi" {
  project        = var.project_id
  region         = google_cloudfunctions_function.psi.region
  cloud_function = google_cloudfunctions_function.psi.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${var.service_account_email}"
}

resource "google_cloudfunctions_function_iam_member" "invoker_crux" {
  project        = var.project_id
  region         = google_cloudfunctions_function.crux.region
  cloud_function = google_cloudfunctions_function.crux.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${var.service_account_email}"
}
```

- [ ] **Step 2: Adicionar OIDC token nos schedulers para autenticar as chamadas**

Localizar o bloco `google_cloud_scheduler_job.scheduler_job_psi` e adicionar `oidc_token` dentro de `http_target`:
```hcl
  http_target {
    http_method = "GET"
    uri         = "https://${google_cloudfunctions_function.psi.region}-${var.project_id}.cloudfunctions.net/${local.cf_name_psi}"
    oidc_token {
      service_account_email = var.service_account_email
    }
  }
```

Repetir para `scheduler_job_crux`:
```hcl
  http_target {
    http_method = "GET"
    uri         = "https://${google_cloudfunctions_function.psi.region}-${var.project_id}.cloudfunctions.net/${local.cf_name_crux}"
    oidc_token {
      service_account_email = var.service_account_email
    }
  }
```

- [ ] **Step 3: Validar Terraform**

```bash
cd terraform
terraform validate
```
Expected: `Success! The configuration is valid.`

- [ ] **Step 4: Commit**

```bash
git add terraform/main.tf
git commit -m "fix: restrict Cloud Functions IAM to service account, add OIDC auth to schedulers"
```

---

## Task 8 (Opcional): Migrar para Cloud Functions Gen 2

**Files:**
- Modify: `terraform/main.tf`

> **Atenção:** Esta tarefa é destrutiva — o Terraform vai destruir as gen 1 e criar gen 2. Execute em horário de baixo tráfego e avise os stakeholders. O nome dos recursos muda, então URLs dos endpoints também mudam.

Gen 2 requer um bucket GCS para o build source e usa `google_cloudfunctions2_function`.

- [ ] **Step 1: Substituir o recurso PSI gen 1 por gen 2**

Remover o bloco `google_cloudfunctions_function.psi` e substituir por:
```hcl
resource "google_cloudfunctions2_function" "psi" {
  project     = var.project_id
  name        = local.cf_name_psi
  description = "Execution of PageSpeed Insights API to collect performance metrics"
  location    = var.region

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
    available_memory      = "512M"
    timeout_seconds       = 540
    service_account_email = var.service_account_email
    environment_variables = {
      PROJECT_BUCKET_GCS = local.bucket_name
      PSI_KEY            = var.psi_key
      BQ_DATASET_ID      = local.dataset_id
    }
  }

  depends_on = [null_resource.cf_code_zip]
}
```

- [ ] **Step 2: Substituir o recurso CrUX gen 1 por gen 2**

Remover o bloco `google_cloudfunctions_function.crux` e substituir por:
```hcl
resource "google_cloudfunctions2_function" "crux" {
  project     = var.project_id
  name        = local.cf_name_crux
  description = "Execution of CrUX API to collect performance metrics"
  location    = var.region

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
    available_memory      = "256M"
    timeout_seconds       = 120
    service_account_email = var.service_account_email
    environment_variables = {
      PROJECT_BUCKET_GCS = local.bucket_name
      PROJECT_DATASET_BQ = local.dataset_id
      PROJECT_NAME       = local.project_id
    }
  }

  depends_on = [null_resource.cf_code_zip]
}
```

- [ ] **Step 3: Atualizar os recursos IAM para gen 2**

Substituir `google_cloudfunctions_function_iam_member` por `google_cloudfunctions2_function_iam_member`:
```hcl
resource "google_cloudfunctions2_function_iam_member" "invoker_psi" {
  project        = var.project_id
  location       = google_cloudfunctions2_function.psi.location
  cloud_function = google_cloudfunctions2_function.psi.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${var.service_account_email}"
}

resource "google_cloudfunctions2_function_iam_member" "invoker_crux" {
  project        = var.project_id
  location       = google_cloudfunctions2_function.crux.location
  cloud_function = google_cloudfunctions2_function.crux.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${var.service_account_email}"
}
```

- [ ] **Step 4: Atualizar URLs dos schedulers para gen 2**

Gen 2 usa um formato de URL diferente. Substituir as URIs nos schedulers:
```hcl
# PSI scheduler
uri = google_cloudfunctions2_function.psi.service_config[0].uri

# CrUX scheduler
uri = google_cloudfunctions2_function.crux.service_config[0].uri
```

- [ ] **Step 5: Validar Terraform**

```bash
cd terraform
terraform validate
```
Expected: `Success! The configuration is valid.`

- [ ] **Step 6: Commit**

```bash
git add terraform/main.tf
git commit -m "feat: migrate Cloud Functions from gen 1 to gen 2"
```
