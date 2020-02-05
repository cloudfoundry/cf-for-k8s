#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

istioctl_version="$(istioctl version --remote=false)"
if [ ${istioctl_version} != "1.4.2" ]; then
  echo "Please install version 1.4.2 of istioctl"
  exit 1
fi

echo "generating Istio resource definitions..."
istioctl manifest generate -f "${SCRIPT_DIR}/istio-config.yml" | \
  ytt --ignore-unknown-comments -f - -f "${SCRIPT_DIR}/overlays.yml" \
  > "${SCRIPT_DIR}/../../config/_ytt_lib/istio/all.yml"
