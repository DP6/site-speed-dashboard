#!/bin/bash
set -e

PROJECT_PREFIX=$1
PROJECT_ID=$2
REGION=${3:-us-central1}

if [ -z "$PROJECT_PREFIX" ] || [ -z "$PROJECT_ID" ]; then
  echo "Usage: sh terraform_deploy.sh <project_prefix> <project_id> [region]"
  echo "Example: sh terraform_deploy.sh mkt-data mkt-data-analytics us-central1"
  exit 1
fi

echo "==> Deploying PSI Cloud Run Job..."
gcloud run jobs deploy ${PROJECT_PREFIX}-sitespeed-psi \
  --source functions/psi \
  --region $REGION \
  --project $PROJECT_ID

echo "==> Deploying CrUX Cloud Run Job..."
gcloud run jobs deploy ${PROJECT_PREFIX}-sitespeed-crux \
  --source functions/crux \
  --region $REGION \
  --project $PROJECT_ID

echo "==> Running Terraform..."
cd terraform && terraform init && terraform apply -auto-approve

echo "==> Deploy finished successfully!"
