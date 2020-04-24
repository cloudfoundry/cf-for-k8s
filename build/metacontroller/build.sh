#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "generating Metacontroller resource definitions..."
ytt -f "${SCRIPT_DIR}/_vendir/manifests" \
    -f "${SCRIPT_DIR}/pin-image-to-digest.yml" > "${SCRIPT_DIR}/../../config/_ytt_lib/metacontroller/rendered.yml"
