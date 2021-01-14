#!/usr/bin/env bash

set -euo pipefail

function log_into_gke_cluster() {
  local ROOT_DIR
  local project_name

  ROOT_DIR=$PWD

  echo "$GKE_SERVICE_ACCOUNT_KEY" > $ROOT_DIR/service-account.json

  project_name=$(jq -r .project_id $ROOT_DIR/service-account.json)

  gcloud auth activate-service-account --key-file=$ROOT_DIR/service-account.json
  gcloud container clusters get-credentials "${CLUSTER_NAME}" --zone "${GCP_ZONE}" --project "${project_name}"
}
