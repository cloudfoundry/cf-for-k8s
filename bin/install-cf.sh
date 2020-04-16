#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage $(basename "$0") <path-to-install-values-yaml>"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"

ytt_args=()
for file in "$@"; do
  if [[ ! -r "${file}" ]]; then
    echo "File $file does not exist"
    exit 1
  fi
  ytt_args+=("-f" "$file")
done


# Deploy CF for Kubernetes
kapp deploy -a cf -f <(ytt -f "${CONFIG_DIR}" "${ytt_args[@]}") -y
