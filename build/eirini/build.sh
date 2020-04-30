#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

echo "generating Eirini resource definitions..."
helm template --namespace=cf-system "${SCRIPT_DIR}/_vendir/eirini" \
    --values="${SCRIPT_DIR}/eirini-values.yml" |
    ytt --ignore-unknown-comments -f - \
        -f "${SCRIPT_DIR}/add-namespaces-overlay.yml" \
        >"${SCRIPT_DIR}/../../config/_ytt_lib/eirini/rendered.yml"
