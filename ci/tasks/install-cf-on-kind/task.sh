#!/bin/bash
set -eou pipefail

source cf-for-k8s-ci/ci/helpers/auth-to-gcp.sh

echo "Generating install values..."
cf-for-k8s/hack/generate-values.sh -d vcap.me -g gcp-service-account.json > cf-install-values/cf-install-values.yml

echo "Uploading cf-install-values.yml..."
gcloud beta compute \
  scp cf-install-values/cf-install-values.yml ${user_host}:/tmp \
  --zone "us-central1-a" > /dev/null

cat <<EOT > remote-install-cf.sh
#!/usr/bin/env bash
set -euo pipefail

export HOME=/tmp/kind
export PATH=/tmp/kind/bin:/tmp/kind/go/bin:$PATH

CF_VALUES=/tmp/cf-install-values.yml
CF_RENDERED=/tmp/cf-rendered.yml
cd /tmp/kind/cf-for-k8s
ytt -f config -f config-optional/ingressgateway-service-nodeport.yml -f config-optional/remove-resource-requirements.yml -f config-optional/add-metrics-server-components.yml -f config-optional/patch-metrics-server.yml -f \$CF_VALUES > \$CF_RENDERED

kapp deploy -f \$CF_RENDERED -a cf -y
EOT
chmod +x remote-install-cf.sh

echo "Uploading remote-install-cf.sh..."
gcloud beta compute \
  scp remote-install-cf.sh ${user_host}:/tmp \
  --zone "us-central1-a" > /dev/null

echo "Running remote-install-cf.sh..."
gcloud beta compute \
  ssh ${user_host} \
  --command "/tmp/remote-install-cf.sh" \
  --zone "us-central1-a"
