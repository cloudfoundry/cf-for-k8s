#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

echo "generating QuarksSecret resource definitions..."

chart_yaml=${SCRIPT_DIR}/_vendir/deploy/helm/quarks-secret/Chart.yaml

# won't be necessary after this PR is merged and we start using a QuarksSecret that includes the change:
# https://github.com/cloudfoundry-incubator/quarks-secret/pull/92
sed -i -r 's/x.x.x/0.0.0/g' ${chart_yaml}

# some versions of sed create this strange file with a -r suffix
if [[ -f ${SCRIPT_DIR}/_vendir/deploy/helm/quarks-secret/Chart.yaml-r ]]; then
  rm ${SCRIPT_DIR}/_vendir/deploy/helm/quarks-secret/Chart.yaml-r
fi

helm template cf-quarks-secret --namespace=cf-system "${SCRIPT_DIR}/_vendir/deploy/helm/quarks-secret" \
  --values="${SCRIPT_DIR}/quarks-values.yaml" |
  ytt --ignore-unknown-comments -f - > "${SCRIPT_DIR}/../../config/quarks-secret/_ytt_lib/quarks-secret/rendered.yml"

git checkout ${chart_yaml}
