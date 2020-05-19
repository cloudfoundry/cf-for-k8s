#!/usr/bin/env bash
set -eu

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "generating Metacontroller resource definitions..."
ytt -f "${SCRIPT_DIR}/osl-compliant-image-override.yml" -f "${SCRIPT_DIR}/_vendir/manifests" | kbld -f - > "${SCRIPT_DIR}/../../config/_ytt_lib/metacontroller/rendered.yml"
