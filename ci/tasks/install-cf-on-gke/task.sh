#!/bin/bash
set -euo pipefail

source cf-for-k8s-ci/ci/helpers/generate-values.sh
source cf-for-k8s-ci/ci/helpers/gke.sh
source cf-for-k8s-ci/ci/helpers/uptimer-config.sh

if [[ -z "${DOMAIN}" ]]; then
  echo "DOMAIN must be specified"
  exit 1
fi

echo "Installation Configuration"
echo "=========================="
echo "External Registry: ${USE_EXTERNAL_APP_REGISTRY}"
echo "Upgrade: ${UPGRADE}"
echo "Uptimer: ${UPTIMER}"
echo -e "\n"

if [[ -d pool-lock ]]; then
  if [[ -d tf-vars ]]; then
    echo "You may not specify both pool-lock and tf-vars"
    exit 1
  fi
  cluster_name="$(cat pool-lock/name)"
  load_balancer_static_ip="$(jq -r '.lb_static_ip' pool-lock/metadata)"
elif [[ -d tf-vars ]]; then
  if [[ -d terraform ]]; then
    cluster_name="$(cat tf-vars/env-name.txt)"
    load_balancer_static_ip="$(jq -r '.lb_static_ip' terraform/metadata)"
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
  echo "Copying bosh vars store from previous install..."
  mkdir -p "/tmp/${DNS_DOMAIN}"
  cp env-metadata/cf-vars.yaml "/tmp/${DNS_DOMAIN}/cf-vars.yaml"
  echo "NOTE: the values we're currently not rotating are:"
  cat env-metadata/cf-vars.yaml | yq -r 'keys'
  echo "(we are also not testing rotating our app_registry credentials)"
  echo ""
  echo "Generating install values with cf-vars..."
else
  echo "Generating install values..."
fi

generate_values > cf-install-values.yml
cf-for-k8s/hack/generate-internal-values.sh -v cf-install-values.yml > cf-internal-values.yml

echo "load_balancer:" >> cf-install-values.yml
echo "  static_ip: ${load_balancer_static_ip}" >> cf-install-values.yml
password="$(bosh interpolate --path /cf_admin_password cf-internal-values.yml)"

echo "Installing CF..."
rendered_yaml="/tmp/rendered.yml"
additional_args=""

if [[ "${USE_EXTERNAL_DB}" == "true" ]]; then
  additional_args="-f db-metadata/db-values.yaml"
fi

if [[ "${USE_EXTERNAL_BLOBSTORE}" == "true" ]]; then
  additional_args+="-f blobstore-metadata/blobstore-values.yaml"
fi

ytt -f cf-for-k8s/config -f cf-install-values.yml -f cf-internal-values.yml ${additional_args} > ${rendered_yaml}

if [[ "${UPTIMER}" == "true" ]]; then
  echo "Running with uptimer"
  write_uptimer_deploy_config "${password}" "${rendered_yaml}"
  mkdir -p uptimer-result
  UPTIMER_RESULT_FILE_PATH="uptimer-result/result.json"
  set +e
  uptimer -useBuildpackDetection=true -configFile=/tmp/uptimer-config.json -resultFile=${UPTIMER_RESULT_FILE_PATH}
  uptimer_exit_code=$?
  set -e

  if [[ "${EMIT_UPTIMER_METRICS_TO_WAVEFRONT}" == "true" ]]; then
    echo "Emitting uptimer metrics"
    source runtime-ci/tasks/shared-functions
    push_uptimer_metrics_to_wavefront "${SOURCE_PIPELINE}" "${UPTIMER_RESULT_FILE_PATH}"
  fi

  if [[ "$uptimer_exit_code" != "0" ]]; then
    exit 1
  fi
else
  kapp deploy -a cf -f ${rendered_yaml} -y
fi

echo ${password} > env-metadata/cf-admin-password.txt
echo "${DNS_DOMAIN}" > env-metadata/dns-domain.txt
bosh interpolate --path /default_ca/ca /tmp/${DNS_DOMAIN}/cf-vars.yaml > env-metadata/default_ca.ca
cp "/tmp/${DNS_DOMAIN}/cf-vars.yaml" env-metadata
