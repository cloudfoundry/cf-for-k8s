#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

echo "generating Eirini resource definitions..."
ytt --ignore-unknown-comments \
  -f "${SCRIPT_DIR}/_vendir/eirini/core" \
  -f "${SCRIPT_DIR}/_vendir/eirini/events" \
  -f "${SCRIPT_DIR}/_vendir/eirini/workloads" \
  -f "${SCRIPT_DIR}/overlays" |
  kbld -f - \
    >"${SCRIPT_DIR}/../../config/eirini/_ytt_lib/eirini/rendered.yml"
