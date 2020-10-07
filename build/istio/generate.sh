#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DESIRED_ISTIO_VERSION=$(< "${SCRIPT_DIR}/values.yaml" yq -r .istio_version)

set +eu
istioctl_version="$(istioctl version --remote=false)"
if [[ ${istioctl_version} != "${DESIRED_ISTIO_VERSION}" ]]; then
  echo "Downloading istioctl version ${DESIRED_ISTIO_VERSION} to tmp" >&2
  mkdir -p /tmp/istio >&2
  pushd /tmp/istio > /dev/null
    curl -s -L https://istio.io/downloadIstio | ISTIO_VERSION=${DESIRED_ISTIO_VERSION} sh - >&2
    mv istio-*/bin/istioctl . >&2
  popd > /dev/null

  export PATH="/tmp/istio:${PATH}" >&2
fi
set -eu

echo "generating Istio resource definitions..." >&2
istioctl manifest generate -f "${SCRIPT_DIR}/istioctl-values.yaml" "$@" | \
  ytt --ignore-unknown-comments \
    -f "$SCRIPT_DIR/values.yaml" \
    -f - \
    -f "${SCRIPT_DIR}/overlays"
