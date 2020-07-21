#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

echo "generating Postgresql resource definitions..."
helm template cf-db --namespace=cf-db "${SCRIPT_DIR}/_vendir/bitnami/postgresql" \
        --values="${SCRIPT_DIR}/init-db-values.yml" |
    ytt --ignore-unknown-comments -f - |
    kbld -f - > "${SCRIPT_DIR}/../../config/postgres/_ytt_lib/postgres/rendered.yml"
