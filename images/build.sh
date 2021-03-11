#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KBLD_CONFIG_DIR="$(mktemp -d)"
KBLD_LOCK_FILE="${SCRIPT_DIR}/kbld.lock.yml"

function cleanup() {
  echo "Cleaning up..."
  rm -rf "${KBLD_CONFIG_DIR}"
}

trap cleanup EXIT

pushd ${SCRIPT_DIR} > /dev/null
  vendir sync

  for component in $(ls build); do
    mkdir "${KBLD_CONFIG_DIR}/${component}"
    "${SCRIPT_DIR}/build/${component}/generate-kbld-config.sh" "${KBLD_CONFIG_DIR}/${component}/kbld.yml"
  done

  kbld -f "${KBLD_CONFIG_DIR}" -f <(ytt -f "${SCRIPT_DIR}/../config/" -f "${SCRIPT_DIR}/../sample-cf-install-values.yml") --lock-output "${KBLD_LOCK_FILE}"
popd > /dev/null
