#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

echo "generating QuarksSecret resource definitions..."

chart_yaml=${SCRIPT_DIR}/_vendir/deploy/helm/quarks-secret/Chart.yaml

# some versions of sed create this strange file with a -r suffix
if [[ -f ${SCRIPT_DIR}/_vendir/deploy/helm/quarks-secret/Chart.yaml-r ]]; then
  rm ${SCRIPT_DIR}/_vendir/deploy/helm/quarks-secret/Chart.yaml-r
fi

helm template cf-quarks-secret --namespace=cf-system "${SCRIPT_DIR}/_vendir/deploy/helm/quarks-secret" \
  --values="${SCRIPT_DIR}/quarks-values.yaml" |
  ytt --ignore-unknown-comments -f - |
  kbld -f "${SCRIPT_DIR}/image-override.yml" -f - > "${SCRIPT_DIR}/../../config/quarks-secret/_ytt_lib/quarks-secret/rendered.yml"

git checkout ${chart_yaml}
