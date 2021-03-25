#!/bin/bash

set -euo pipefail

source cf-for-k8s-ci/ci/helpers/gke.sh

function main() {
  local cluster_name
  cluster_name="$(cat pool-lock/name)"
  gcloud_auth "${cluster_name}"

  local config="${PWD}/integration-config/${INTEGRATION_CONFIG_FILE}"
  local kube_config="${PWD}/kube-config.yml"

  pushd cf-k8s-networking/test/acceptance > /dev/null
    ./bin/test_local "${config}" "${kube_config}"
  popd
}

main
