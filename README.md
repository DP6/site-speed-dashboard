# Site Speed Dashboard

<div align="center">
<img src="https://raw.githubusercontent.com/DP6/templates-centro-de-inovacoes/main/public/images/centro_de_inovacao_dp6.png" height="100px" />
</div>

<p align="center">
  <a href="#badge">
    <img alt="semantic-release" src="https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg">
  </a>
  <a href="https://www.codacy.com/gh/DP6/3ef6b0f421634cb881539914e7fa59f1/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=DP6/{{repo}}&amp;utm_campaign=Badge_Coverage"><img alt="Code coverage" src="https://app.codacy.com/project/badge/Coverage/3ef6b0f421634cb881539914e7fa59f1"/></a>
  <a href="#badge">
    <img alt="Test" src="https://github.com/dp6/site-speed-dashboard/actions/workflows/test.yml/badge.svg">
  </a>
  <a href="https://www.codacy.com/gh/DP6/site-speed-dashboard/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=DP6/site-speed-dashboard&amp;utm_campaign=Badge_Grade">
    <img alt="Code quality" src="https://app.codacy.com/project/badge/Grade/3ef6b0f421634cb881539914e7fa59f1">
  </a>
</p>

Site Speed Dashboard is an open source tool developed by DP6 to help you measure performance in your websites. The project is structured in [Google Cloud Plataform](https://console.cloud.google.com) (GCP) and composed of a JS script that will extract simulated data from Google's [PageSpeed Insights](https://developers.google.com/speed/docs/insights/v5/about) API, and a Python script that will extract real data from Google's [Chrome User Experience Report](https://developers.google.com/web/tools/chrome-user-experience-report) public dataset in Google BigQuery.

All this data is then stored in BigQuery's tables and connected to a Google Data Studio Dashboard in order to help you visualize the data and get insights in how to improve performance!

# Content
- [GCP Requirements](#gcp-requirements)
- [Local Environment Requirements](#local-environment-requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Dashboard](#dashboard)
- [How to contribute](#how-to-contribute)
- [Support](#support)

# GCP Requirements 

This project creates resources in Google Cloud Plataform to extract and store data. Because of that, the first requirement is to have a **GCP's project with active billing**.
## **Resources**
During terraform's execution, these resources will be created:
- Cloud Storage
- BigQuery
- Cloud Function
- Cloud Scheduler

And in order for the creation to succeed, you'll need to active the following:
- Cloud Storage
- BigQuery API
- Cloud Functions API
- Cloud Build API
- Cloud Resource Manager API
- BigQuery Data Transfer API
- Cloud Scheduler API

If you are not familiar with activating resouces in GCP, follow [this](https://cloud.google.com/endpoints/docs/openapi/enable-api) guide and search for the sources listed above. 

## **Service Account**
After the activation, you'll need to create a [Service Account](https://cloud.google.com/iam/docs/creating-managing-service-accounts) with the following permissions:
- Storage Object Admin
- Cloud Functions Admin
- BigQuery Admin
- Service Account User

## **Next Steps**

In the next steps, you'll need to run a terraform script. You can use a local environment in order to do so or you can run directly into GCP, using [Google Cloud Shell](https://cloud.google.com/shell/docs). 

We personally recommend using Google Cloud Shell because of its facility, as you don't need to install anything. If you're going to use your local environment, check [Local Environment Requirements](#local-environment-requirements). Otherwise, skip this section.

# Local Environment Requirements

In order for the code to run locally, you'll need to install the following:

- Package [zip](https://www.tecmint.com/install-zip-and-unzip-in-linux/)
- Package [unzip](https://www.tecmint.com/install-zip-and-unzip-in-linux/)
- Package [curl](https://www.tecmint.com/install-curl-in-linux/)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install?hl=pt-br)
- [Terraform](https://www.terraform.io/downloads.html)

After that, you'll need to set GOOGLE_APPLICATION_CREDENTIALS environment variable with the service account key. You can download this key from GCP, in the same place where the service account was created. If you're not familiar with setting environment variables, follow [this](https://cloud.google.com/docs/authentication/getting-started#setting_the_environment_variable) guide.

  
# Installation

## Create an API Key

To be able to get CrUX and PSI data, you'll need an API key, which you can get in [this](https://developers.google.com/web/tools/chrome-user-experience-report/api/guides/getting-started#APIKey) link, which will automatically create a key and return its value. You can also create an API key directly in the [credentials page](https://console.developers.google.com/apis/credentials) in GCP.

## Running Terraform Script

Clone this project into you local computer or to Cloud Shell.

```console
git clone https://github.com/DP6/site-speed-dashboard.git
```

After that, run the following:

```console
cd site-speed-dashboard/
sh terraform_deploy.sh
```

Wait for the code to run and after finishing, check GCP in order to confirm if the resources were created successfully.

# Configuration

### URLs
The next step is to set the configuration file that was created in Cloud Storage. To do that, access [this](https://console.cloud.google.com/storage/browser) link and search for a bucket with the name [project-prefix]-sitespeed, with project-prefix beeing the variable of the same name that was set during terraform's execution. 

Within the bucket, open the "config" folder, find the "config.json" file and download it. Open the file and edit the URLS array, adding the URLs that you want to analyze in the format shown below.

<img src="https://raw.githubusercontent.com/DP6/templates-centro-de-inovacoes/main/public/images/site_speed_dashboard_config_file.png"/>

### CrUX Countries (Optional)
In case you want to change in which countries crux data will be extracted, you can also alter the COUNTRIES array, adding or removing countries using the [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) format.

```
"COUNTRIES": ["br", "fr"]   // In this case, Brazil's and France's 
                            // data will be extracted  
```

### Deployment
After finishing the setup, upload the file into the same GCP bucket, overwriting the previous file. After that, the setup is finished and you'll start collecting performance data on your BQ tables!

# Dashboard
After installing and seting up the urls and countries, you'll have the "back-end" done and ready to work, but you still won't be able to visualize the data you are collecting. In order to do that, you'll have to follow through the steps below.

## Duplicating Data Sources
In the dataset created in your GCP project, you can find three tables:

- crux_table
- psi_metrics_results
- psi_suggestion_results

Each table will compose a different Data Studio data source and all these datasources will compose the dashboard, that, in turn, will create the data visualization. You'll have to duplicate all the data sources below:

- [CrUX Table - Template [Data Source - Bigquery]](https://datastudio.google.com/datasources/521b4106-d002-45d4-b428-f359ea9d4b33)
- [PSI Table Results - Template [Data Source - Bigquery]](https://datastudio.google.com/datasources/4184e227-e6bf-4323-b224-f684ad58ee9b)
- [PSI Table Suggestions - Template [Data Source - Bigquery]](https://datastudio.google.com/datasources/1313adbe-412a-406e-beef-e7313238c43b)

To duplicate, follow the steps below:
1. Click the
<img src="https://lh3.googleusercontent.com/V6jKS63Ya_QVoDo7PfKcheXZ-j9Zcih4H8VxaBOMSGesBIT2m97cFIsHazykztgXwOrS=w36"  style="height: 20px; width:20px;"/> icon 
on the top menu of each data source and then click "Copy Data Source".

2. Select the GCP project in which you created your site speed dashboard BigQuery tables

3. Select the BigQuery data source created when executing the terraform script

4. Select the corresponding table that matches the Data Studio data source selected

At the end, you'll have 3 new data sources connected to your tables.

## Duplicating the dashboard template

After duplicating the data sources, you'll need to duplicate the dashboard itself. To do that, follow this steps:

1. Open the [Site Speed Dashboard - Template](https://datastudio.google.com/reporting/19dd4850-55a1-42ef-9de1-43f776b9ddbb/page/p_3exd7jginc) dashboard.

2. Duplicate the dashboard by clicking at the 
<img src="https://lh3.googleusercontent.com/Kz1M6nAGoh2SvZ44eaZ_c1scIotCBl_qJzei-gV6Q3RwuLm21XVaqfQMUK2bgzxmoLU=w36-h36" style="height: 20px; width:20px;"/> icon on the top menu and then at <img src="https://lh3.googleusercontent.com/V6jKS63Ya_QVoDo7PfKcheXZ-j9Zcih4H8VxaBOMSGesBIT2m97cFIsHazykztgXwOrS=w36"  style="height: 20px; width:20px;"/> *Make a Copy* option.

3. Link each Original Data Source to your newly created data sources

4. Click *Copy Report*.

Now you have a beautiful dashboard ready to be used!

# How to contribute

Pull requests are welcome! We will love help to evolve this module. Feel free to browse open issues looking for something you can do. If you have a new feature or bug, please open a new issue to be followed up by our team.

## Mandatory requirements

Only contributions that meet the following requirements will be accepted:

- [Commit pattern](https://www.conventionalcommits.org/en/v1.0.0/)

## Api Docs

- [PSI](https://github.com/dp6/site-speed-dashboard/blob/master/functions/psi)
- [CrUX](https://github.com/dp6/site-speed-dashboard/blob/master/functions/crux)

# Support:

**DP6 Koopa-troopa Team**

_e-mail: <koopas@dp6.com.br>_

<img src="https://raw.githubusercontent.com/DP6/templates-centro-de-inovacoes/main/public/images/koopa.png" height="100px" width=50px/>
