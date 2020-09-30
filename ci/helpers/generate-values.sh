#!/usr/bin/env bash

VARS_FILE="/tmp/${DOMAIN}/cf-vars.yaml"

function generate_values() {
  # Make sure bosh binary exists
  bosh --version >/dev/null

  bosh interpolate --vars-store=${VARS_FILE} <(
    cat <<EOF
variables:
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
    alternative_names:
    - "*.apps.${DOMAIN}"
    extended_key_usage:
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

add_metrics_server_components: ${ADD_METRICS_SERVER_COMPONENTS}
enable_automount_service_account_token: ${ENABLE_AUTOMOUNT_SERVICE_ACCOUNT_TOKEN}
enable_load_balancer: ${ENABLE_LOAD_BALANCER}
metrics_server_prefer_internal_kubelet_address: ${METRICS_SERVER_PREFER_INTERNAL_KUBELET_ADDRESS}
remove_resource_requirements: ${REMOVE_RESOURCE_REQUIREMENTS}
use_first_party_jwt_tokens: ${USE_FIRST_PARTY_JWT_TOKENS}
EOF

  if [[ "${USE_EXTERNAL_APP_REGISTRY}" == "true" ]]; then
    cat <<EOT

app_registry:
  hostname: ${APP_REGISTRY_HOSTNAME}
  repository_prefix: ${APP_REGISTRY_REPOSITORY_PREFIX}
  username: ${APP_REGISTRY_USERNAME}
  password: ${APP_REGISTRY_PASSWORD}
EOT
  elif [[ -n "${GCP_SERVICE_ACCOUNT_JSON_FILE:=}" ]]; then
    cat <<EOF

app_registry:
  hostname: gcr.io
  repository_prefix: gcr.io/$( bosh interpolate ${GCP_SERVICE_ACCOUNT_JSON_FILE} --path=/project_id )/cf-workloads
  username: _json_key
  password: |
$(cat ${GCP_SERVICE_ACCOUNT_JSON_FILE} | sed -e 's/^/    /')
EOF
  fi
}
