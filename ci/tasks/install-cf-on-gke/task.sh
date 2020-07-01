#!/bin/bash -eu

echo "Installation Configuration"
echo "=========================="
echo "External Registry: ${USE_EXTERNAL_APP_REGISTRY}"
echo "Upgrade: ${UPGRADE}"
echo "Uptimer: ${UPTIMER}"
echo -e "\n"

source cf-for-k8s-ci/ci/helpers/gke.sh
source cf-for-k8s-ci/ci/helpers/uptimer-config.sh

cluster_name="$(cat pool-lock/name)"
gcloud_auth "${cluster_name}"

DNS_DOMAIN="${cluster_name}.k8s-dev.relint.rocks"

if [[ "${UPGRADE}" == "true" ]]; then
  echo "Copying bosh vars store from latest install"
  mkdir -p "/tmp/${cluster_name}.k8s-dev.relint.rocks"
  cp env-metadata/cf-vars.yaml "/tmp/${cluster_name}.k8s-dev.relint.rocks/cf-vars.yaml"
  echo "NOTE: the values we're currently not rotating are:"
  cat env-metadata/cf-vars.yaml | yq -r 'keys'
  echo "(we're also not testing rotating our app_registry credentials)"
  echo ""
  echo "Generating install values with cf-vars..."
else
  echo "Generating install values..."
fi

if [[ "${USE_EXTERNAL_APP_REGISTRY}" == "true" ]]; then
  cf-for-k8s/hack/generate-values.sh --cf-domain "${DNS_DOMAIN}" > cf-values.yml
cat <<EOT >> cf-values.yml
app_registry:
   hostname: ${APP_REGISTRY_HOSTNAME}
   repository: ${APP_REGISTRY_REPOSITORY}
   username: ${APP_REGISTRY_USERNAME}
   password: ${APP_REGISTRY_PASSWORD}
EOT
else
  cf-for-k8s/hack/generate-values.sh --cf-domain "${DNS_DOMAIN}" --gcr-service-account-json gcp-service-account.json > cf-values.yml
fi

echo "istio_static_ip: $(jq -r '.lb_static_ip' pool-lock/metadata)" >> cf-values.yml

echo "Installing CF..."
ytt -f cf-for-k8s/config -f cf-values.yml > /tmp/manifest.yml
password=$(bosh interpolate --path /cf_admin_password cf-values.yml)
if [[ "${UPTIMER}" == "true" ]]; then
  echo "Running with uptimer"
  write_uptimer_deploy_config
  uptimer -configFile /tmp/uptimer-config.json
else
  kapp deploy -a cf -f /tmp/manifest.yml -y
fi

echo ${password} > env-metadata/cf-admin-password.txt
echo "${DNS_DOMAIN}" > env-metadata/dns-domain.txt
cp "/tmp/${cluster_name}.k8s-dev.relint.rocks/cf-vars.yaml" env-metadata
