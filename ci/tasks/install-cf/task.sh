#!/bin/bash -eu

source cf-for-k8s-ci/ci/helpers/gke.sh

cluster_name="$(cat pool-lock/name)"
gcloud_auth "${cluster_name}"

DNS_DOMAIN="${cluster_name}.k8s-dev.relint.rocks"
cf-for-k8s/hack/confirm-network-policy.sh "${cluster_name}" "$GCP_PROJECT_ZONE"

echo "Generating install values..."
cf-for-k8s/hack/generate-values.sh --cf-domain "${DNS_DOMAIN}" > cf-install-values.yml

cat >> cf-install-values.yml <<EOT
app_registry:
   hostname: '$APP_REGISTRY_HOSTNAME'
   repository_prefix: '$APP_REGISTRY_REPOSITORY_PREFIX'
   username: '$APP_REGISTRY_USERNAME'
   password: |
     $APP_REGISTRY_PASSWORD
istio_static_ip: $(jq -r '.lb_static_ip' pool-lock/metadata)
EOT

echo "Installing CF..."
if [[ -z "$ADDITIONAL_YAML_CONFIG" ]]; then
   kapp deploy -a cf -f <(ytt -f cf-for-k8s/config -f cf-install-values.yml) -y
else
   kapp deploy -a cf -f <(ytt -f cf-for-k8s/config -f cf-install-values.yml -f "$ADDITIONAL_YAML_CONFIG" ) -y
fi

bosh interpolate --path /cf_admin_password cf-install-values.yml > env-metadata/cf-admin-password.txt
bosh interpolate --path /default_ca/ca /tmp/${DNS_DOMAIN}/cf-vars.yaml > env-metadata/default_ca.ca
echo "${DNS_DOMAIN}" > env-metadata/dns-domain.txt
