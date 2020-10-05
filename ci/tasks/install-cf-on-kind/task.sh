#!/bin/bash
set -euo pipefail

source cf-for-k8s-ci/ci/helpers/auth-to-gcp.sh
source cf-for-k8s-ci/ci/helpers/generate-values.sh

echo "Generating install values..."
generate_values > cf-install-values.yml
cf-for-k8s/hack/generate-internal-values.sh -v cf-install-values.yml > cf-internal-values.yml

echo "Uploading cf-for-k8s repo..."
gcloud beta compute \
  scp --recurse cf-for-k8s ${user_host}:/tmp/kind/ --compress \
  --zone "us-central1-a" > /dev/null

echo "Replacing CI directory..."
gcloud beta compute \
  scp --recurse cf-for-k8s-ci/ci ${user_host}:/tmp/kind/cf-for-k8s/ --compress \
  --zone "us-central1-a" > /dev/null

echo "Uploading cf-install-values.yml..."
gcloud beta compute \
  scp cf-install-values.yml ${user_host}:/tmp \
  --zone "us-central1-a" > /dev/null

echo "Uploading cf-internal-values.yml..."
gcloud beta compute \
  scp cf-internal-values.yml ${user_host}:/tmp \
  --zone "us-central1-a" > /dev/null

cat <<EOT > remote-install-cf.sh
#!/usr/bin/env bash
set -euo pipefail

export HOME=/tmp/kind
export PATH=/tmp/kind/bin:/tmp/kind/go/bin:$PATH

CF_RENDERED=/tmp/cf-rendered.yml
cd /tmp/kind/cf-for-k8s
ytt -f config -f /tmp/cf-install-values.yml -f /tmp/cf-install-values.yml > \$CF_RENDERED

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

password="$(bosh interpolate --path /cf_admin_password cf-internal-values.yml)"
echo ${password} > env-metadata/cf-admin-password.txt
