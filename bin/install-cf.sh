#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage $(basename "$0") <path-to-install-values-yaml>"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"

cf_install_values_path="$1"

if [[ ! -r "${cf_install_values_path}" ]]; then
  echo "Unable to read CF install values file: ${cf_install_values_path}"
  exit 1
fi

# Deploy CF for Kubernetes
kapp deploy -a cf -f <(ytt -f "${CONFIG_DIR}" -f "${cf_install_values_path}") -y
