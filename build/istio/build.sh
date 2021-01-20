#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

${SCRIPT_DIR}/generate.sh "$@" | kbld -f - > "${SCRIPT_DIR}/../../config/istio/istio-generated/xxx-generated-istio.yaml"

# save the current Istio version in the networking configs
# NOTE: this project uses python yq module (https://kislyuk.github.io/yq/)
ISTIO_VERSION="$(< "${SCRIPT_DIR}/values.yaml" yq -r .istio_version)"
sed -r -i'' 's/(return)(.*\..*\..*)$/\1 "'${ISTIO_VERSION}'"/' "${SCRIPT_DIR}/../../config/istio/upgrade-istio-sidecars-job.yml"
