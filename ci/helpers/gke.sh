#!/bin/bash

gcloud_auth() {
  local cluster_name_file=$1

  cluster_name=$(cat ${cluster_name_file})
  export KUBECONFIG=kube-config.yml
  echo ${GCP_SERVICE_ACCOUNT_JSON} > gcp-service-account.json
  gcloud auth activate-service-account --key-file=gcp-service-account.json --project=${GCP_PROJECT_NAME} >/dev/null 2>&1
  gcloud container clusters get-credentials "${cluster_name}" --zone ${GCP_PROJECT_ZONE} >/dev/null 2>&1

}
