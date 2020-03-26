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

EOF
  exit 1
}

if [[ $# -lt 1 ]]; then
  usage_text >&2
fi

while [[ $# -gt 0 ]]
do
i=$1
case $i in
  -d=*|--cf-domain=*)
  DOMAIN="${i#*=}"
  shift
  ;;
  -d|--cf-domain)
  DOMAIN="${2}"
  shift
  shift
  ;;
  -g=*|--gcr-service-account-json=*)
  GCP_SERVICE_ACCOUNT_JSON="${i#*=}"
  shift
  ;;
  -g|--gcr-service-account-json)
  GCP_SERVICE_ACCOUNT_JSON="${2}"
  shift
  shift
  ;;
  *)
  echo -e "Error: Unknown flag: ${i/=*/}\n" >&2
  usage_text >&2
  exit 1
  ;;
esac
done

if [[ -z ${DOMAIN:=} ]]; then
  echo "Missing required flag: -d / --cf-domain" >&2
  exit 1
fi

if [[ -n ${GCP_SERVICE_ACCOUNT_JSON:=} ]]; then
  if [[ ! -r ${GCP_SERVICE_ACCOUNT_JSON} ]]; then
    echo "Error: Unable to read GCP service account JSON from file: ${GCP_SERVICE_ACCOUNT_JSON}" >&2
    exit 1
  fi
fi

VARS_FILE="/tmp/${DOMAIN}/cf-vars.yaml"

# Make sure bosh binary exists
bosh --version >/dev/null

bosh interpolate --vars-store=${VARS_FILE} <(cat <<EOF
variables:
- name: cf_admin_password
  type: password
- name: blobstore_secret_key
  type: password
- name: db_admin_password
  type: password
- name: capi_db_password
  type: password
- name: uaa_db_password
  type: password
- name: log_cache_client_password
  type: password
- name: uaa_admin_client_secret
  type: password
- name: uaa_encryption_key_passphrase
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
    - "*.${DOMAIN}"
    - "*.cf-system.svc.cluster.local"
    extended_key_usage:
    - client_auth
    - server_auth

- name: uaa_jwt_policy_signing_key
  type: certificate
  options:
    ca: default_ca
    common_name: uaa_jwt_policy_signing_key

- name: uaa_login_service_provider
  type: certificate
  options:
    ca: default_ca
    common_name: uaa_login_service_provider

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
EOF
) >/dev/null

cat <<EOF
#@data/values
---
system_domain: "${DOMAIN}"
app_domains:
#@overlay/append
- "${DOMAIN}"
cf_admin_password: $( bosh interpolate ${VARS_FILE} --path=/cf_admin_password )

cf_blobstore:
  secret_key: $( bosh interpolate ${VARS_FILE} --path=/blobstore_secret_key )

cf_db:
  admin_password: $( bosh interpolate ${VARS_FILE} --path=/db_admin_password )

capi:
  database:
    password: $( bosh interpolate ${VARS_FILE} --path=/capi_db_password )

log_cache_client:
  id: log-cache
  secret: $( bosh interpolate ${VARS_FILE} --path=/log_cache_client_password )

system_certificate:
  #! This certificates and keys are base64 encoded and should be valid for *.system.cf.example.com
  crt: &crt $( bosh interpolate ${VARS_FILE} --path=/system_certificate/certificate | base64 | tr -d '\n' )
  key: &key $( bosh interpolate ${VARS_FILE} --path=/system_certificate/private_key | base64 | tr -d '\n' )
  ca: $( bosh interpolate ${VARS_FILE} --path=/system_certificate/ca | base64 | tr -d '\n' )

log_cache_ca:
  crt: $( bosh interpolate ${VARS_FILE} --path=/log_cache_ca/certificate | base64 | tr -d '\n' )
  key: $( bosh interpolate ${VARS_FILE} --path=/log_cache_ca/private_key | base64 | tr -d '\n' )

log_cache:
  crt: $( bosh interpolate ${VARS_FILE} --path=/log_cache/certificate | base64 | tr -d '\n' )
  key: $( bosh interpolate ${VARS_FILE} --path=/log_cache/private_key | base64 | tr -d '\n' )

log_cache_metrics:
  crt: $( bosh interpolate ${VARS_FILE} --path=/log_cache_metrics/certificate | base64 | tr -d '\n' )
  key: $( bosh interpolate ${VARS_FILE} --path=/log_cache_metrics/private_key | base64 | tr -d '\n' )

log_cache_gateway:
  crt: $( bosh interpolate ${VARS_FILE} --path=/log_cache_gateway/certificate | base64 | tr -d '\n' )
  key: $( bosh interpolate ${VARS_FILE} --path=/log_cache_gateway/private_key | base64 | tr -d '\n' )

log_cache_syslog:
  crt: $( bosh interpolate ${VARS_FILE} --path=/log_cache_syslog/certificate | base64 | tr -d '\n' )
  key: $( bosh interpolate ${VARS_FILE} --path=/log_cache_syslog/private_key | base64 | tr -d '\n' )

uaa:
  database:
    password: $( bosh interpolate ${VARS_FILE} --path=/uaa_db_password )
  admin_client_secret: $( bosh interpolate ${VARS_FILE} --path=/uaa_admin_client_secret )
  certificate:
    crt: *crt
    key: *key
  jwt_policy:
    signing_key: |
$( bosh interpolate "${VARS_FILE}" --path=/uaa_jwt_policy_signing_key/private_key | sed -e 's#^#      #' )
  encryption_key:
    passphrase: $( bosh interpolate "${VARS_FILE}" --path=/uaa_encryption_key_passphrase )
  login:
    service_provider:
      key: |
$( bosh interpolate "${VARS_FILE}" --path=/uaa_login_service_provider/private_key | sed -e 's#^#        #' )
      certificate: |
$( bosh interpolate "${VARS_FILE}" --path=/uaa_login_service_provider/certificate | sed -e 's#^#        #' )

doppler:
  tls:
    crt: *crt
    key: *key

eirini:
  tls:
    crt: *crt
    key: *key
EOF

if [[ -n "${GCP_SERVICE_ACCOUNT_JSON:=}" ]]; then
  cat <<EOF

app_registry:
  hostname: gcr.io
  repository: gcr.io/$( bosh interpolate ${GCP_SERVICE_ACCOUNT_JSON} --path=/project_id )/cf-workloads
  username: _json_key
  password: |
$( cat ${GCP_SERVICE_ACCOUNT_JSON} | sed -e 's/^/    /' )
EOF
fi
