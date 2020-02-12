#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "generating Docker Registry resource definitions..."
helm template docker-registry --namespace=docker-registry "${SCRIPT_DIR}/_vendir/stable/docker-registry/" --values="${SCRIPT_DIR}/helm-values.yml" | ytt --ignore-unknown-comments -f - > "${SCRIPT_DIR}/../../config/_ytt_lib/docker-registry/rendered.yml"
