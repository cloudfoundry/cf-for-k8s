#!/bin/bash
set -eou pipefail

K8S_MINOR_VERSION=$(yq -r '.oldest_version' cf-for-k8s/supported_k8s_versions.yml)
PATCH_VERSION=$(wget -q https://registry.hub.docker.com/v1/repositories/kindest/node/tags -O - | jq -r '.[].name' | grep -E "^v${K8S_MINOR_VERSION}.[0-9]+$" | cut -d. -f3 | sort -rn | head -1)
K8S_VERSION=${K8S_MINOR_VERSION}.${PATCH_VERSION}

vm_name=$(jq -r '.vm_name' terraform/metadata)
user_host="tester@${vm_name}"
echo '((ci_k8s_gcp_service_account_json))' > gcp-service-account.json
gcloud auth activate-service-account --key-file=gcp-service-account.json --project='((ci_k8s_gcp_project_name))' >/dev/null 2>&1
gcloud components install beta -q
mkdir $HOME/.ssh
chmod 0700 $HOME/.ssh
jq -r '.vm_ssh_private_key' terraform/metadata > $HOME/.ssh/google_compute_engine
jq -r '.vm_ssh_public_key' terraform/metadata > $HOME/.ssh/google_compute_engine.pub
chmod 0600 $HOME/.ssh/google_compute_engine

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
  --project "((ci_k8s_gcp_project_name))" --zone "us-central1-a" > /dev/null

echo "Running remote-check-permissions.sh..."
gcloud beta compute \
  ssh ${user_host} \
  --command "/tmp/remote-check-permissions.sh" \
  --project "((ci_k8s_gcp_project_name))" --zone "us-central1-a"

cat <<EOT > remote-create-kind-cluster.sh
#!/usr/bin/env bash
set -euo pipefail

export HOME=/tmp/kind
export PATH=/tmp/kind/bin:/tmp/kind/go/bin:$PATH
kind create cluster --config=\$HOME/cf-for-k8s/deploy/kind/cluster.yml \
  --image kindest/node:v${K8S_VERSION}
EOT
chmod +x remote-create-kind-cluster.sh

echo "Uploading cf-for-k8s repo..."
gcloud beta compute \
  scp --recurse cf-for-k8s ${user_host}:/tmp/kind/ --compress \
  --project "((ci_k8s_gcp_project_name))" --zone "us-central1-a" > /dev/null

echo "Uploading remote-create-kind-cluster.sh..."
gcloud beta compute \
  scp remote-create-kind-cluster.sh ${user_host}:/tmp/ \
  --project "((ci_k8s_gcp_project_name))" --zone "us-central1-a" > /dev/null

echo "Running remote-create-kind-cluster.sh..."
gcloud beta compute \
  ssh ${user_host} \
  --command "/tmp/remote-create-kind-cluster.sh" \
  --project "((ci_k8s_gcp_project_name))" --zone "us-central1-a"