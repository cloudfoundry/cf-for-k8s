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
EOF
