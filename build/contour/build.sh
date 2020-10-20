#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DESIRED_CONTOUR_VERSION=$(< "${SCRIPT_DIR}/values.yaml" yq -r .contour_version)

set +eu

echo "Downloading Contour installation templates..."
wget "https://raw.githubusercontent.com/projectcontour/contour/v${DESIRED_CONTOUR_VERSION}/examples/render/contour.yaml" -O - | \
  ytt --ignore-unknown-comments \
    -f - |
  kbld -f - > "${SCRIPT_DIR}/../../config/ingress/_ytt_lib/contour/generated/xxx-contour.yaml"

