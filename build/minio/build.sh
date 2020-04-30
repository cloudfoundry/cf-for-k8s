#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

echo "Generating Minio resource definitions..."

helm template cf-blobstore --namespace=cf-blobstore "${SCRIPT_DIR}/_vendir/stable/minio/" |
  ytt --ignore-unknown-comments -f - -f "${SCRIPT_DIR}/scrub_default_creds.yml" |
  kbld -f - \
  > "${SCRIPT_DIR}/../../config/_ytt_lib/minio/rendered.yml"
