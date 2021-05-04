#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

${SCRIPT_DIR}/generate.sh "$@" | kbld -f - > "${SCRIPT_DIR}/../../config/istio/istio-generated/xxx-generated-istio.yaml"

# Save the current Istio version in the networking configs
# NOTE: this project uses python yq module (https://kislyuk.github.io/yq/)
ISTIO_VERSION="$(< "${SCRIPT_DIR}/values.yaml" yq -r .istio_version)"
cat <<EOF > "${SCRIPT_DIR}/../../config/istio/istio-version.star"
def istio_version():
  return "${ISTIO_VERSION}"
end
EOF
