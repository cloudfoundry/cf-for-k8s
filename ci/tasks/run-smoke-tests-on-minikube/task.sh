#!/bin/bash
set -eou pipefail

source cf-for-k8s-ci/ci/helpers/auth-to-gcp.sh

cat <<EOT > remote-run-smoke-tests.sh
#!/usr/bin/env bash
set -euo pipefail

export HOME=/tmp/minikube
export PATH=/tmp/minikube/bin:/tmp/minikube/go/bin:\$PATH
export CGO_ENABLED=0
export GO111MODULE=on

DOMAIN="\$(minikube ip).nip.io"
export SMOKE_TEST_API_ENDPOINT="api.\${DOMAIN}"
export SMOKE_TEST_APPS_DOMAIN="apps.\${DOMAIN}"
export SMOKE_TEST_USERNAME=admin
# The yq command to interpolate the CF admin password needs to run on the Concourse worker
export SMOKE_TEST_PASSWORD="$(yq -r '.cf_admin_password' cf-install-values/cf-install-values.yml)"
export SMOKE_TEST_SKIP_SSL=true
/tmp/minikube/cf-for-k8s/hack/run-smoke-tests.sh
EOT
chmod +x remote-run-smoke-tests.sh

echo "Uploading remote-run-smoke-tests.sh..."
gcloud beta compute \
  scp remote-run-smoke-tests.sh ${user_host}:/tmp \
  --zone "us-central1-a" > /dev/null

echo "Running remote-run-smoke-tests.sh..."
gcloud beta compute \
  ssh ${user_host} \
  --command "/tmp/remote-run-smoke-tests.sh" \
  --zone "us-central1-a"
