#!/bin/bash
set -eou pipefail

source cf-for-k8s-ci/ci/helpers/auth-to-gcp.sh

cat <<EOT > remote-ensure-api-healthy.sh
#!/usr/bin/env bash
set -euo pipefail

export HOME=/tmp/kind
export PATH=/tmp/kind/bin:/tmp/kind/go/bin:$PATH

function retry {
  local retries=\$1
  shift

  local count=0
  until "\$@"; do
    exit=\$?
    wait=\$((2 ** count))
    count=\$((count + 1))
    if [[ \$count < \$retries ]]; then
      echo "Retry \$count/\$retries exited \$exit, retrying in \$wait seconds..."
      sleep \$wait
    else
      echo "Retry \$count/\$retries exited \$exit, no more retries left."
      return \$exit
    fi
  done
  return 0
}

retry 7 cf api api.vcap.me --skip-ssl-validation
EOT
chmod +x remote-ensure-api-healthy.sh

echo "Uploading remote-ensure-api-healthy.sh..."
gcloud beta compute \
  scp remote-ensure-api-healthy.sh ${user_host}:/tmp \
  --zone "us-central1-a" > /dev/null

echo "Running remote-ensure-api-healthy.sh..."
gcloud beta compute \
  ssh ${user_host} \
  --command "/tmp/remote-ensure-api-healthy.sh" \
  --zone "us-central1-a"