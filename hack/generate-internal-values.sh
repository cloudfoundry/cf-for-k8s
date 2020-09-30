#!/usr/bin/env bash

# This is a hack! see https://github.com/cloudfoundry/cf-for-k8s/blob/develop/hack/README.md
set -euo pipefail

function usage_text() {
  cat <<EOF
Usage:
  $(basename "$0")

flags:
  -v, --values-file
      (required) Path to your "external" values file
      (see the sample-cf-install-values directory for examples)

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
  -v=* | --values-file=*)
    VALUES_FILE="${i#*=}"
    shift
    ;;
  -v | --values-file)
    VALUES_FILE="${2}"
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

if [[ -z ${VALUES_FILE:=} ]]; then
  echo "Missing required flag: -v / --values-file" >&2
  exit 1
fi

DOMAIN="$(yq -r '.system_domain' "${VALUES_FILE}")"

if [[ -z ${DOMAIN:=} ]]; then
  echo "Unable to extract system_domain from the specified values file" >&2
  exit 1
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
- name: uaa_login_secret
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
- name: uaa_login_service_provider
  type: certificate
  options:
    ca: default_ca
    common_name: uaa_login_service_provider
EOF
) >/dev/null

cat <<EOF
#@data/values
---
cf_admin_password: $(bosh interpolate ${VARS_FILE} --path=/cf_admin_password)

blobstore:
  secret_access_key: $(bosh interpolate ${VARS_FILE} --path=/blobstore_secret_key)

cf_db:
  admin_password: $(bosh interpolate ${VARS_FILE} --path=/db_admin_password)

capi:
  cc_username_lookup_client_secret: $(bosh interpolate ${VARS_FILE} --path=/cc_username_lookup_client_secret)
  cf_api_controllers_client_secret: $(bosh interpolate ${VARS_FILE} --path=/cf_api_controllers_client_secret)
  database:
    password: $(bosh interpolate ${VARS_FILE} --path=/capi_db_password)
    encryption_key: $(bosh interpolate ${VARS_FILE} --path=/capi_db_encryption_key)

internal_certificate:
  #! This certificates and keys are base64 encoded and should be valid for *.cf-system.svc.cluster.local
  crt: $(bosh interpolate ${VARS_FILE} --path=/internal_certificate/certificate | base64 | tr -d '\n')
  key: $(bosh interpolate ${VARS_FILE} --path=/internal_certificate/private_key | base64 | tr -d '\n')
  ca: $(bosh interpolate ${VARS_FILE} --path=/internal_certificate/ca | base64 | tr -d '\n')

uaa:
  database:
    password: $(bosh interpolate ${VARS_FILE} --path=/uaa_db_password)
  admin_client_secret: $(bosh interpolate ${VARS_FILE} --path=/uaa_admin_client_secret)
  jwt_policy:
    signing_key: |
$(bosh interpolate "${VARS_FILE}" --path=/uaa_jwt_policy_signing_key/private_key | sed -e 's#^#      #')
  encryption_key:
    passphrase: $(bosh interpolate "${VARS_FILE}" --path=/uaa_encryption_key_passphrase)
  login:
    service_provider:
      key: |
$(bosh interpolate "${VARS_FILE}" --path=/uaa_login_service_provider/private_key | sed -e 's#^#        #')
      certificate: |
$(bosh interpolate "${VARS_FILE}" --path=/uaa_login_service_provider/certificate | sed -e 's#^#        #')
  login_secret: $(bosh interpolate "${VARS_FILE}" --path=/uaa_login_secret)
EOF
