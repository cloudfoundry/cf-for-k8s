#!/bin/bash
set -eou pipefail

vm_name=$(jq -r '.vm_name' terraform/metadata)
user_host="tester@${vm_name}"
export GCP_SERVICE_ACCOUNT_JSON_FILE="${PWD}/gcp-service-account.json"
echo ${GCP_KEY} > "${GCP_SERVICE_ACCOUNT_JSON_FILE}"
gcloud config set project "${GCP_PROJECT_NAME}"
gcloud auth activate-service-account --key-file="${GCP_SERVICE_ACCOUNT_JSON_FILE}" >/dev/null 2>&1
gcloud components install beta -q
mkdir $HOME/.ssh
chmod 0700 $HOME/.ssh
jq -r '.vm_ssh_private_key' terraform/metadata > $HOME/.ssh/google_compute_engine
jq -r '.vm_ssh_public_key' terraform/metadata > $HOME/.ssh/google_compute_engine.pub
chmod 0600 $HOME/.ssh/google_compute_engine
