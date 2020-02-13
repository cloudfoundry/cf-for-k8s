#!/usr/bin/env bash

set -eu

## Usage: ./generate-values.sh <my-domain>
## where my-domain will be used as both the system domain and app domain.

# Make sure bosh binary exists
bosh --version >/dev/null

VARS_FILE=/tmp/cf-vars.yaml
DOMAIN=$1

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
- name: uaa_admin_client_secret
  type: password
- name: docker_registry_http_secret
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

doppler:
  tls:
    crt: *crt
    key: *key

eirini:
  tls:
    crt: *crt
    key: *key

docker_registry:
  http_secret: $( bosh interpolate ${VARS_FILE} --path=/docker_registry_http_secret )
EOF
