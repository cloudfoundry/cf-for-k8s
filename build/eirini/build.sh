#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# either supply path to Eirini Helm chart or assume `eirini/eirini` has been loaded into workstation's local Helm repos cache
EIRINI_RELEASE_PATH="${1:-eirini/eirini}"

echo "generating Eirini resource definitions..."
helm template --namespace=cf-system "${EIRINI_RELEASE_PATH}" --values="${SCRIPT_DIR}/eirini-values.yml" | ytt --ignore-unknown-comments -f - -f "${SCRIPT_DIR}/add-namespaces-overlay.yml" > "${SCRIPT_DIR}/../../config/_ytt_lib/eirini/rendered.yml"

