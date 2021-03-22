#!/usr/bin/env bash

set -euo pipefail

source cf-for-k8s-ci/ci/tasks/cf-k8s-networking/helpers.sh

# ENV
: "${GCP_SERVICE_ACCOUNT_KEY:?}"

: "${CLOUDSDK_COMPUTE_REGION:?}"
: "${CLOUDSDK_COMPUTE_ZONE:?}"
: "${ENABLE_IP_ALIAS:?}"
: "${GCP_PROJECT:?}"
: "${MACHINE_TYPE:?}"
: "${NUM_NODES:?}"
: "${EPHEMERAL_CLUSTER:?}"
: "${REGIONAL_CLUSTER:?}"
: "${REUSE_CLUSTER:?}"

function latest_cluster_version() {
  if [ "${REGIONAL_CLUSTER}" = true ]; then
    gcloud container get-server-config --region $CLOUDSDK_COMPUTE_REGION 2>/dev/null | yq .validMasterVersions[0] -r
  else
    gcloud container get-server-config --region $CLOUDSDK_COMPUTE_ZONE 2>/dev/null | yq .validMasterVersions[0] -r
  fi
}

function create_cluster() {
    gcloud auth activate-service-account --key-file=<(echo "${GCP_SERVICE_ACCOUNT_KEY}") --project="${GCP_PROJECT}" 1>/dev/null 2>&1
    additional_args=()

    if [ "${REGIONAL_CLUSTER}" = true ]; then
        additional_args+=("--region")
        additional_args+=("${CLOUDSDK_COMPUTE_REGION}")
    fi

    if gcloud container clusters describe ${CLUSTER_NAME} "${additional_args[@]}" > /dev/null; then
      if [ "${REUSE_CLUSTER}" = true ]; then
        echo "${CLUSTER_NAME} already exists! Removing CF..."
        gcloud container clusters get-credentials "${CLUSTER_NAME}"
        kapp delete -a cf -y
        return
      else
        echo "${CLUSTER_NAME} already exists! Destroying..."
        gcloud container clusters delete ${CLUSTER_NAME} --quiet "${additional_args[@]}"
      fi
    fi

    if [ "${ENABLE_IP_ALIAS}" = true ]; then
        additional_args+=("--enable-ip-alias")
    fi

    echo "Creating cluster: ${CLUSTER_NAME} ..."
    gcloud container clusters create ${CLUSTER_NAME} \
        --cluster-version=$(latest_cluster_version) \
        --machine-type=${MACHINE_TYPE} \
        --labels team=cf-k8s-networking,ci=true,ephemeral="$EPHEMERAL_CLUSTER" \
        --enable-network-policy \
        --num-nodes "${NUM_NODES}" \
        "${additional_args[@]}"
}

function main() {
    initialize_gke_env_vars
    create_cluster
}

main
