#!/usr/bin/env bash

# NOTE: Because these are designed to be used in concourse tasks, they use
# exit 1. In my experience, this means that running them locally will cause
# your terminal, tmux session, or ssh session to exit.

function target_cf_with_install_values() {
    if [ -z "${INSTALL_VALUES_FILEPATH}" ]; then
        echo "INSTALL_VALUES_FILEPATH is empty. Defaulting to use \"cf-install-values/cf-install-values.yml\" file"
        INSTALL_VALUES_FILEPATH="cf-install-values/cf-install-values.yml"
    fi

    if [ -z "${TARGET_ORG}" ]; then
        echo "TARGET_ORG is empty. Please supply the org to target"
        exit 1
    fi

    if [ -z "${TARGET_SPACE}" ]; then
        echo "TARGET_SPACE is empty. Please supply the space to target"
        exit 1
    fi

    local cf_domain=$(cat "${INSTALL_VALUES_FILEPATH}" | \
        grep system_domain | awk '{print $2}' | tr -d '"')

    cf api --skip-ssl-validation "https://api.${cf_domain}"
    local password=$(cat "${INSTALL_VALUES_FILEPATH}" | \
        grep cf_admin_password | awk '{print $2}')
    cf auth "admin" "${password}"

    cf target -o "${TARGET_ORG}" -s "${TARGET_SPACE}"
}

function target_k8s_cluster() {
    if [ -z "${CLUSTER_NAME}" ]; then
        echo "CLUSTER_NAME is empty. Please supply the name of the cluster you wish to target."
        exit 1
    fi

    if [ -z "${GCP_SERVICE_ACCOUNT_KEY}" ]; then
        echo "GCP_SERVICE_ACCOUNT_KEY is empty. Please supply the GCP Service Account Key to access \"${CLUSTER_NAME}\". Note, this is the actual key, not a filepath to the key."
        exit 1
    fi

    if [ -z "${GCP_PROJECT}" ]; then
        echo "GCP_PROJECT is empty. Please supply the GCP project that ${CLUSTER_NAME} is part of."
        exit 1
    fi

    if [ -z "${GCP_REGION}" ]; then
        echo "GCP_REGION is empty. Please supply the GCP region that ${CLUSTER_NAME} is part of."
        exit 1
    fi

    gcloud auth activate-service-account --key-file=<(echo "${GCP_SERVICE_ACCOUNT_KEY}") --project="${GCP_PROJECT}"  1>/dev/null 2>&1
    gcloud container clusters get-credentials ${CLUSTER_NAME} --region="${GCP_REGION}" 1>/dev/null 2>&1
}

function initialize_gke_env_vars() {
  if [ -f "gke-env-metadata/cluster_name" ]; then
    export CLUSTER_NAME="$(cat gke-env-metadata/cluster_name)"
  fi
  if [ -f "gke-env-metadata/cf_domain" ]; then
    export CF_DOMAIN="$(cat gke-env-metadata/cf_domain)"
  fi
  # TODO initialize other env vars if necessary
}
