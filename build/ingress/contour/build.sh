#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DESIRED_CONTOUR_VERSION="main"

set +eu

echo "Downloading Contour installation templates..."
wget "https://raw.githubusercontent.com/projectcontour/contour/${DESIRED_CONTOUR_VERSION}/examples/render/contour.yaml" -O - | \
  kbld -f - > "${SCRIPT_DIR}/../../../config/ingress/_ytt_lib/contour/generated/xxx-contour.yaml"

cp "${SCRIPT_DIR}/../common-values.yaml" "${SCRIPT_DIR}/../../../config/ingress/_ytt_lib/contour/generated/xxx-common-values.yaml"
