#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

${SCRIPT_DIR}/generate.sh "$@" | kbld -f - > \
  "${SCRIPT_DIR}/../../config/ingress/_ytt_lib/istio/istio-generated/xxx-generated-istio.yaml"

# save the current Istio version in the networking configs
ISTIO_VERSION="$(< "${SCRIPT_DIR}/values.yaml" yq -r .istio_version)"
sed -r -i'' 's/(return)(.*\..*\..*)$/\1 "'${ISTIO_VERSION}'"/' \
  "${SCRIPT_DIR}/../../config/ingress/_ytt_lib/istio/templates/upgrade-istio-sidecars-job.yaml"
