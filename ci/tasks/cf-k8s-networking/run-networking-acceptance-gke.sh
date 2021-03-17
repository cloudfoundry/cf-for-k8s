#!/bin/bash

set -euo pipefail

source cf-k8s-networking-ci/ci/tasks/helpers.sh

# ENV
: "${INTEGRATION_CONFIG_FILE:?}"
: "${CLOUDSDK_COMPUTE_REGION:?}"
: "${CLOUDSDK_COMPUTE_ZONE:?}"
: "${GCP_SERVICE_ACCOUNT_KEY:?}"
: "${GCP_PROJECT:?}"

function main() {
    export KUBECONFIG=kubeconfig/config

    gcloud auth activate-service-account --key-file=<(echo "${GCP_SERVICE_ACCOUNT_KEY}") --project="${GCP_PROJECT}" 1>/dev/null 2>&1
    gcloud container clusters get-credentials ${CLUSTER_NAME} 1>/dev/null 2>&1

    local kubeconfig_path="${PWD}/${KUBECONFIG}"
    local config="${PWD}/integration-config/${INTEGRATION_CONFIG_FILE}"

    pushd cf-k8s-networking/test/acceptance > /dev/null
        ./bin/test_local "${config}" "${kubeconfig_path}"
    popd
}

initialize_gke_env_vars
main
