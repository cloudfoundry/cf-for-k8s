#!/bin/bash
set -eou pipefail

K8S_MINOR_VERSION=$(yq -r ".${VERSION_SELECTOR}" cf-for-k8s-cluster-versions/supported_k8s_versions.yml)
PATCH_VERSION=$(wget -q https://registry.hub.docker.com/v1/repositories/kindest/node/tags -O - | jq -r '.[].name' | grep -E "^v${K8S_MINOR_VERSION}.[0-9]+$" | cut -d. -f3 | sort -rn | head -1)
K8S_VERSION=${K8S_MINOR_VERSION}.${PATCH_VERSION}

source cf-for-k8s-ci/ci/helpers/auth-to-gcp.sh

cat <<EOT > remote-check-permissions.sh
while [[ ! -w /tmp/kind ]]; do
  echo "Waiting for write access to /tmp/kind..."
  sleep 5
done
EOT
chmod +x remote-check-permissions.sh

echo "Uploading remote-check-permissions.sh..."
gcloud beta compute \
  scp remote-check-permissions.sh ${user_host}:/tmp/ \
  --zone "us-central1-a" > /dev/null

echo "Running remote-check-permissions.sh..."
gcloud beta compute \
  ssh ${user_host} \
  --command "/tmp/remote-check-permissions.sh" \
  --zone "us-central1-a"

case $K8S_VERSION in
  1.22.2)
    # kindest/node:v1.22.2 has an issue https://github.com/kubernetes-sigs/kind/issues/2518
    KIND_VERSION=1.22.1
    ;;
  *)
    KIND_VERSION=$K8S_VERSION
    ;;
esac

cat <<EOT > remote-create-kind-cluster.sh
#!/usr/bin/env bash
set -euo pipefail

export HOME=/tmp/kind
export PATH=/tmp/kind/bin:/tmp/kind/go/bin:$PATH
kind create cluster --config=\$HOME/cluster.yml \
  --image kindest/node:v${KIND_VERSION}
EOT
chmod +x remote-create-kind-cluster.sh

echo "Uploading kind cluster.yml..."
gcloud beta compute \
  scp cf-for-k8s/deploy/kind/cluster.yml ${user_host}:/tmp/kind/cluster.yml \
  --zone "us-central1-a" > /dev/null

echo "Uploading remote-create-kind-cluster.sh..."
gcloud beta compute \
  scp remote-create-kind-cluster.sh ${user_host}:/tmp/ \
  --zone "us-central1-a" > /dev/null

echo "Running remote-create-kind-cluster.sh..."
gcloud beta compute \
  ssh ${user_host} \
  --command "/tmp/remote-create-kind-cluster.sh" \
  --zone "us-central1-a"
