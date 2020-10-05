#!/bin/bash

function gcloud_auth() {
  local cluster_name=$1

  export KUBECONFIG=kube-config.yml
  export GCP_SERVICE_ACCOUNT_JSON_FILE="${PWD}/gcp-service-account.json"
  echo ${GCP_SERVICE_ACCOUNT_JSON} > "${GCP_SERVICE_ACCOUNT_JSON_FILE}"
  gcloud auth activate-service-account --key-file="${GCP_SERVICE_ACCOUNT_JSON_FILE}" --project=${GCP_PROJECT_NAME} >/dev/null 2>&1
  gcloud container clusters get-credentials "${cluster_name}" --zone ${GCP_PROJECT_ZONE} >/dev/null 2>&1
}
