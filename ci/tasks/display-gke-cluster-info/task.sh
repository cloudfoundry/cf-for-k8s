#!/bin/bash

set -euo pipefail

source cf-for-k8s-ci/ci/helpers/gke.sh

cluster_name="$(cat pool-lock/name)"
gcloud_auth "${cluster_name}"

cat <<EOF
Cluster version: $(kubectl version -o json | jq -r '.serverVersion.gitVersion')
Kubectl version: $(kubectl version -o json | jq -r '.clientVersion.gitVersion')
EOF
