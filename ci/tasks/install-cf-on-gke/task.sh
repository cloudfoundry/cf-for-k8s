#!/bin/bash -eu

echo "Installation Configuration"
echo "=========================="
echo "External Registry: ${USE_EXTERNAL_APP_REGISTRY}"
echo "Upgrade: ${UPGRADE}"
echo "Uptimer: ${UPTIMER}"
echo -e "\n"

source cf-for-k8s-ci/ci/helpers/gke.sh
source cf-for-k8s-ci/ci/helpers/uptimer-config.sh

if [[ -d pool-lock ]]; then
  if [[ -d tf-vars ]]; then
    echo "You may not specify both pool-lock and tf-vars"
    exit 1
  fi
  cluster_name="$(cat pool-lock/name)"
  istio_static_ip="$(jq -r '.lb_static_ip' pool-lock/metadata)"
elif [[ -d tf-vars ]]; then
  if [[ -d terraform ]]; then
    cluster_name="$(cat tf-vars/env-name.txt)"
    istio_static_ip="$(jq -r '.lb_static_ip' terraform/metadata)"
  else
    echo "You must provide both tf-vars and terraform inputs together"
    exit 1
  fi
else
  echo "You must provide either pool-lock or tf-vars"
  exit 1
fi

gcloud_auth "${cluster_name}"
DNS_DOMAIN="${cluster_name}.${DOMAIN}"

if [[ "${UPGRADE}" == "true" ]]; then
  echo "Copying bosh vars store from latest install"
  mkdir -p "/tmp/${DNS_DOMAIN}"
  cp env-metadata/cf-vars.yaml "/tmp/${DNS_DOMAIN}/cf-vars.yaml"
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
   repository_prefix: ${APP_REGISTRY_REPOSITORY_PREFIX}
   username: ${APP_REGISTRY_USERNAME}
   password: ${APP_REGISTRY_PASSWORD}
EOT
else
  cf-for-k8s/hack/generate-values.sh --cf-domain "${DNS_DOMAIN}" --gcr-service-account-json gcp-service-account.json > cf-values.yml
fi

echo "istio_static_ip: ${istio_static_ip}" >> cf-values.yml
password="$(bosh interpolate --path /cf_admin_password cf-values.yml)"

echo "Installing CF..."
rendered_yaml="/tmp/rendered.yml"
ytt -f cf-for-k8s/config -f cf-values.yml > ${rendered_yaml}
if [[ "${UPTIMER}" == "true" ]]; then
  echo "Running with uptimer"
  write_uptimer_deploy_config "${password}" "${rendered_yaml}"
  mkdir -p uptimer-result
  uptimer -configFile /tmp/uptimer-config.json -resultFile uptimer-result/result.json
else
  kapp deploy -a cf -f ${rendered_yaml} -y
fi

echo ${password} > env-metadata/cf-admin-password.txt
echo "${DNS_DOMAIN}" > env-metadata/dns-domain.txt
bosh interpolate --path /default_ca/ca /tmp/${DNS_DOMAIN}/cf-vars.yaml > env-metadata/default_ca.ca
cp "/tmp/${DNS_DOMAIN}/cf-vars.yaml" env-metadata
