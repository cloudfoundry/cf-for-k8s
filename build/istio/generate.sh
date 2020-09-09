#!/usr/bin/env bash
set -eu


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DESIRED_ISTIO_VERSION=$(< "${SCRIPT_DIR}/values.yaml" yq -r .istio_version)


istioctl_version="$(istioctl version --remote=false)"
if [[ ${istioctl_version} != "${DESIRED_ISTIO_VERSION}" ]]; then
  echo "Please install version ${DESIRED_ISTIO_VERSION} of istioctl: https://github.com/istio/istio/releases/tag/${DESIRED_ISTIO_VERSION}" >&2
  exit 1
fi

echo "generating Istio resource definitions..." >&2
istioctl manifest generate -f "${SCRIPT_DIR}/istioctl-values.yaml" "$@" | \
  ytt --ignore-unknown-comments \
    -f "$SCRIPT_DIR/values.yaml" \
    -f - \
    -f "${SCRIPT_DIR}/overlays"
