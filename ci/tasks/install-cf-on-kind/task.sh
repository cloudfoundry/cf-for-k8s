#!/bin/bash
set -eou pipefail

source cf-for-k8s-ci/ci/helpers/auth-to-gcp.sh

echo "Generating install values..."
cf-for-k8s/hack/generate-values.sh -d vcap.me -g gcp-service-account.json > cf-install-values/cf-install-values.yml

# If VERSION_SELECTOR not passed, will hit default case below.
K8S_MINOR_VERSION=$(yq -r ".${VERSION_SELECTOR}" cf-for-k8s-cluster-versions/supported_k8s_versions.yml)
# heredocs in case statements require no indentation (or tab indentation if used with <<-EOT)
case $K8S_MINOR_VERSION in
  1.18)
echo "*** Kubernetes version $K8S_MINOR_VERSION - applying first party jwt tokens. ***"
cat <<EOT >> cf-install-values/cf-install-values.yml
use_first_party_jwt_tokens: true
EOT
    ;;
  1.19)
echo "*** Kubernetes version $K8S_MINOR_VERSION - applying first party jwt tokens. ***"
cat <<EOT >> cf-install-values/cf-install-values.yml
use_first_party_jwt_tokens: true
EOT
    ;;
  *)
echo "*** Kubernetes version $K8S_MINOR_VERSION - using 3rd party jwt tokens. ***"
    ;;
esac

cat <<EOT >> cf-install-values/cf-install-values.yml
add_metrics_server_components: true
enable_automount_service_account_token: true
metrics_server_prefer_internal_kubelet_address: true
remove_resource_requirements: true

load_balancer:
  enable: false
EOT

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
ytt -f config -f \$CF_VALUES > \$CF_RENDERED

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
