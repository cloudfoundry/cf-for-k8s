#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

echo "generating QuarksSecret resource definitions..."

helm template cf-quarks-secret --namespace=cf-system "${SCRIPT_DIR}/_vendir/deploy/helm/quarks-secret" \
  --values="${SCRIPT_DIR}/quarks-values.yaml" |
  ytt --ignore-unknown-comments -f - |
<<<<<<< HEAD
  kbld -f - > "${SCRIPT_DIR}/../../config/quarks-secret/_ytt_lib/quarks-secret/rendered.yml"
=======
  kbld -f - > "${SCRIPT_DIR}/../../config/quarks-secret/_ytt_lib/quarks-secret/rendered.yml"
>>>>>>> 9b53ca7... Refactor quarks-secret into its own component directory
