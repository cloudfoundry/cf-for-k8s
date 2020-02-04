#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CONFIG_DIR="${SCRIPT_DIR}/../config"

# TODO add argument check and usage message
cf_install_values_path="$1"

# Deploy CF for Kubernetes
kapp deploy -a cf -f <(ytt -f "${CONFIG_DIR}" -f "${cf_install_values_path}") -y
