#!/usr/bin/env bash

# This is a hack! see https://github.com/cloudfoundry/cf-for-k8s/blob/develop/hack/README.md
set -euo pipefail

function usage_text() {
  cat <<EOF
Usage:
  $(basename "$0")

flags:
  -d, --cf-domain
      (required) Root DNS domain name for the CF install
      (e.g. if CF API at api.inglewood.k8s-dev.relint.rocks, cf-domain = inglewood.k8s-dev.relint.rocks)

  -g, --gcr-service-account-json
      (optional) Filepath to the GCP Service Account JSON describing a service account
      that has permissions to write to the project's container repository.

  -s, --silence-hack-warning
      (optional) Omit hack script warning message.

EOF
  exit 1
}

if [[ $# -lt 1 ]]; then
  usage_text >&2
fi

while [[ $# -gt 0 ]]; do
  i=$1
  case $i in
  -d=* | --cf-domain=*)
    DOMAIN="${i#*=}"
    shift
    ;;
  -d | --cf-domain)
    DOMAIN="${2}"
    shift
    shift
    ;;
  -g=* | --gcr-service-account-json=*)
    GCP_SERVICE_ACCOUNT_JSON_FILE="${i#*=}"
    shift
    ;;
  -g | --gcr-service-account-json)
    GCP_SERVICE_ACCOUNT_JSON_FILE="${2}"
    shift
    shift
    ;;
  -s | --silence-hack-warning)
    SILENCE_HACK_WARNING="true"
    shift
    ;;
  *)
    echo -e "Error: Unknown flag: ${i/=*/}\n" >&2
    usage_text >&2
    exit 1
    ;;
  esac
done

if [[ -z ${SILENCE_HACK_WARNING:=} ]]; then
  echo "WARNING: The hack scripts are intended for development of cf-for-k8s.
  They are not officially supported product bits.  Their interface and behavior
  may change at any time without notice." 1>&2
fi

if [[ -z ${DOMAIN:=} ]]; then
  echo "Missing required flag: -d / --cf-domain" >&2
  exit 1
fi

if [[ -n ${GCP_SERVICE_ACCOUNT_JSON_FILE:=} ]]; then
  if [[ ! -r ${GCP_SERVICE_ACCOUNT_JSON_FILE} ]]; then
    echo "Error: Unable to read GCP service account JSON from file: ${GCP_SERVICE_ACCOUNT_JSON_FILE}" >&2
    exit 1
  fi
fi

VARS_FILE="/tmp/${DOMAIN}/cf-vars.yaml"

# Make sure bosh binary exists
bosh --version >/dev/null

bosh interpolate --vars-store=${VARS_FILE} <(
  cat <<EOF
variables:
- name: cf_admin_password
  type: password
- name: blobstore_secret_key
  type: password
- name: db_admin_password
  type: password
- name: capi_db_password
  type: password
- name: capi_db_encryption_key
  type: password
- name: uaa_db_password
  type: password
- name: uaa_admin_client_secret
  type: password
- name: uaa_encryption_key_passphrase
  type: password
- name: cc_username_lookup_client_secret
  type: password
- name: cf_api_controllers_client_secret
  type: password
- name: default_ca
  type: certificate
  options:
    is_ca: true
    common_name: ca
- name: system_certificate
  type: certificate
  options:
    ca: default_ca
    common_name: "*.${DOMAIN}"
    alternative_names:
    - "*.login.${DOMAIN}"
    - "*.${DOMAIN}"
    - "*.uaa.${DOMAIN}"
    extended_key_usage:
    - server_auth
- name: workloads_certificate
  type: certificate
  options:
    ca: default_ca
    common_name: "*.apps.${DOMAIN}"
    extended_key_usage:
    - server_auth
- name: internal_certificate
  type: certificate
  options:
    ca: default_ca
    common_name: "*.cf-system.svc.cluster.local"
    extended_key_usage:
    - client_auth
    - server_auth

- name: uaa_jwt_policy_signing_key
  type: certificate
  options:
    ca: default_ca
    common_name: uaa_jwt_policy_signing_key

- name: log_cache_ca
  type: certificate
  options:
    is_ca: true
    common_name: log-cache-ca

- name: log_cache
  type: certificate
  options:
    ca: log_cache_ca
    common_name: log-cache
    extended_key_usage:
    - client_auth
    - server_auth

- name: log_cache_syslog
  type: certificate
  options:
    ca: log_cache_ca
    common_name: log-cache-syslog
    extended_key_usage:
    - client_auth
    - server_auth

- name: log_cache_metrics
  type: certificate
  options:
    ca: log_cache_ca
    common_name: log-cache-metrics
    extended_key_usage:
    - client_auth
    - server_auth

- name: log_cache_gateway
  type: certificate
  options:
    ca: log_cache_ca
    common_name: log-cache-gateway
    alternative_names:
    - localhost
    extended_key_usage:
    - client_auth
    - server_auth

- name: metric_proxy_ca
  type: certificate
  options:
    is_ca: true
    common_name: metric-proxy-ca

- name: metric_proxy
  type: certificate
  options:
    ca: metric_proxy_ca
    common_name: metric-proxy
    extended_key_usage:
    - client_auth
    - server_auth
EOF
) >/dev/null

cat <<EOF
#@data/values
---
system_domain: "${DOMAIN}"
app_domains:
#@overlay/append
- "apps.${DOMAIN}"
cf_admin_password: $(bosh interpolate ${VARS_FILE} --path=/cf_admin_password)

cf_blobstore:
  secret_key: $(bosh interpolate ${VARS_FILE} --path=/blobstore_secret_key)

cf_db:
  admin_password: $(bosh interpolate ${VARS_FILE} --path=/db_admin_password)

capi:
  cc_username_lookup_client_secret: $(bosh interpolate ${VARS_FILE} --path=/cc_username_lookup_client_secret)
  cf_api_controllers_client_secret: $(bosh interpolate ${VARS_FILE} --path=/cf_api_controllers_client_secret)
  database:
    password: $(bosh interpolate ${VARS_FILE} --path=/capi_db_password)
    encryption_key: $(bosh interpolate ${VARS_FILE} --path=/capi_db_encryption_key)

system_certificate:
  #! This certificates and keys are base64 encoded and should be valid for *.system.cf.example.com
  crt: $(bosh interpolate ${VARS_FILE} --path=/system_certificate/certificate | base64 | tr -d '\n')
  key: $(bosh interpolate ${VARS_FILE} --path=/system_certificate/private_key | base64 | tr -d '\n')
  ca: $(bosh interpolate ${VARS_FILE} --path=/system_certificate/ca | base64 | tr -d '\n')

workloads_certificate:
  #! This certificates and keys are base64 encoded and should be valid for *.apps.cf.example.com
  crt: $(bosh interpolate ${VARS_FILE} --path=/workloads_certificate/certificate | base64 | tr -d '\n')
  key: $(bosh interpolate ${VARS_FILE} --path=/workloads_certificate/private_key | base64 | tr -d '\n')
  ca: $(bosh interpolate ${VARS_FILE} --path=/workloads_certificate/ca | base64 | tr -d '\n')

internal_certificate:
  #! This certificates and keys are base64 encoded and should be valid for *.cf-system.svc.cluster.local
  crt: $(bosh interpolate ${VARS_FILE} --path=/internal_certificate/certificate | base64 | tr -d '\n')
  key: $(bosh interpolate ${VARS_FILE} --path=/internal_certificate/private_key | base64 | tr -d '\n')
  ca: $(bosh interpolate ${VARS_FILE} --path=/internal_certificate/ca | base64 | tr -d '\n')

log_cache_ca:
  crt: $(bosh interpolate ${VARS_FILE} --path=/log_cache_ca/certificate | base64 | tr -d '\n')
  key: $(bosh interpolate ${VARS_FILE} --path=/log_cache_ca/private_key | base64 | tr -d '\n')

log_cache:
  crt: $(bosh interpolate ${VARS_FILE} --path=/log_cache/certificate | base64 | tr -d '\n')
  key: $(bosh interpolate ${VARS_FILE} --path=/log_cache/private_key | base64 | tr -d '\n')

log_cache_metrics:
  crt: $(bosh interpolate ${VARS_FILE} --path=/log_cache_metrics/certificate | base64 | tr -d '\n')
  key: $(bosh interpolate ${VARS_FILE} --path=/log_cache_metrics/private_key | base64 | tr -d '\n')

log_cache_gateway:
  crt: $(bosh interpolate ${VARS_FILE} --path=/log_cache_gateway/certificate | base64 | tr -d '\n')
  key: $(bosh interpolate ${VARS_FILE} --path=/log_cache_gateway/private_key | base64 | tr -d '\n')

log_cache_syslog:
  crt: $(bosh interpolate ${VARS_FILE} --path=/log_cache_syslog/certificate | base64 | tr -d '\n')
  key: $(bosh interpolate ${VARS_FILE} --path=/log_cache_syslog/private_key | base64 | tr -d '\n')

metric_proxy:
  ca:
    crt: $( bosh interpolate ${VARS_FILE} --path=/metric_proxy_ca/certificate | base64 | tr -d '\n' )
    key: $( bosh interpolate ${VARS_FILE} --path=/metric_proxy_ca/private_key | base64 | tr -d '\n' )
  cert:
    crt: $( bosh interpolate ${VARS_FILE} --path=/metric_proxy/certificate | base64 | tr -d '\n' )
    key: $( bosh interpolate ${VARS_FILE} --path=/metric_proxy/private_key | base64 | tr -d '\n' )

uaa:
  database:
    password: $(bosh interpolate ${VARS_FILE} --path=/uaa_db_password)
  admin_client_secret: $(bosh interpolate ${VARS_FILE} --path=/uaa_admin_client_secret)
  jwt_policy:
    signing_key: |
$(bosh interpolate "${VARS_FILE}" --path=/uaa_jwt_policy_signing_key/private_key | sed -e 's#^#      #')
  encryption_key:
    passphrase: $(bosh interpolate "${VARS_FILE}" --path=/uaa_encryption_key_passphrase)
EOF

if [[ -n "${GCP_SERVICE_ACCOUNT_JSON_FILE:=}" ]]; then
  cat <<EOF

app_registry:
  hostname: gcr.io
  repository_prefix: gcr.io/$( bosh interpolate ${GCP_SERVICE_ACCOUNT_JSON_FILE} --path=/project_id )/cf-workloads
  username: _json_key
  password: |
$(cat ${GCP_SERVICE_ACCOUNT_JSON_FILE} | sed -e 's/^/    /')
EOF

fi

if [[ -n "${K8S_ENV:-}" ]] ; then
    k8s_env_path=$HOME/workspace/relint-ci-pools/k8s-dev/ready/claimed/"$K8S_ENV"
    if [[ -f "$k8s_env_path" ]] ; then
	      ip_addr=$(jq -r .lb_static_ip < "$k8s_env_path")
        echo 1>&2 "Detected \$K8S_ENV environment var; writing \"istio_static_ip: $ip_addr\" entry to end of output"
        echo "
istio_static_ip: $ip_addr
"
    fi
fi
