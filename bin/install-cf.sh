#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CONFIG_DIR="${SCRIPT_DIR}/../config"
HELM_VALUES_DIR="${SCRIPT_DIR}/../helm-values"
CF_FOR_K8S_HELM_CHART="${SCRIPT_DIR}/.."

# TODO add argument check and usage message
cf_install_values_path="$1"

# Deploy CF for Kubernetes
kapp deploy -a cf -y \
  -f <(ytt -f "${CONFIG_DIR}" -f "${cf_install_values_path}") \
  -f <(ytt -f "${HELM_VALUES_DIR}/cf-for-kubernetes-chart-helm-values.yml" -f "${CONFIG_DIR}/values.yml" -f "${cf_install_values_path}" | helm template --namespace cf-system --values - "${CF_FOR_K8S_HELM_CHART}")
