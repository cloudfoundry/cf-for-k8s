#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KBLD_LOCK_FILE="${SCRIPT_DIR}/kbld.lock.yml"
KBLD_CONFIG_DIR="$(mktemp -d)"

function cleanup() {
  echo "Cleaning up..."
  rm -rf "${KBLD_CONFIG_DIR}"
}

trap cleanup EXIT

pushd "${SCRIPT_DIR}" > /dev/null

  vendir sync

  "${SCRIPT_DIR}/generate-kbld-config.sh" "${KBLD_CONFIG_DIR}/kbld.yml"

  kbld -f "${KBLD_CONFIG_DIR}" -f "${SCRIPT_DIR}/statsd-exporter-image.yml" --lock-output "${KBLD_LOCK_FILE}"

popd > /dev/null