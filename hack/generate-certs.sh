#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage $(basename "$0") <domain>"
  exit 1
fi

# Make sure openssl binary exists
openssl x509 -help  2>/dev/null > /dev/null

## Usage: ./generate-certs.sh <my-domain>
## where my-domain will be used as both the system domain and app domain.
DOMAIN=$1
CERT_PATH=$(mktemp -d)
SYSTEM_PATH=${CERT_PATH}/system

# Generate Certs for $DOMAIN
mkdir -p "${CERT_PATH}"
CA_KEY=${CERT_PATH}/ca.key
CA_CERT=${CERT_PATH}/ca.crt
SSL_KEY=${CERT_PATH}/ssl.key
SSL_CSR=${CERT_PATH}/ssl.csr
SSL_CERT=${CERT_PATH}/ssl.crt
openssl genrsa -out "${CA_KEY}" 2048 2>/dev/null > /dev/null

openssl req -x509 -new -nodes -key "${CA_KEY}" \
  -days 365 -out "${CA_CERT}" \
  -subj "/CN=${DOMAIN}" 2>/dev/null > /dev/null

openssl genrsa -out "${SSL_KEY}" 2048 2>/dev/null > /dev/null

openssl req -new -key "${SSL_KEY}" -out "${SSL_CSR}" \
  -subj "/CN=*.${DOMAIN}" 2>/dev/null > /dev/null

openssl x509 -req -in "${SSL_CSR}" -CA "${CA_CERT}" \
  -CAkey "${CA_KEY}" -CAcreateserial -out "${SSL_CERT}" \
  -extfile <(printf "subjectAltName=DNS:*.cf-system.svc.cluster.local,DNS:*.%s\nextendedKeyUsage = 1.3.6.1.5.5.7.3.2,1.3.6.1.5.5.7.3.1" "${DOMAIN}") \
  -days 365 2>/dev/null > /dev/null

# Generate Certs for system components
mkdir -p "${SYSTEM_PATH}"
SYS_CA_KEY=${SYSTEM_PATH}/ca.key
SYS_CA_CERT=${SYSTEM_PATH}/ca.crt

openssl genrsa -out "${SYS_CA_KEY}" 2048 2>/dev/null > /dev/null

openssl req -x509 -new -nodes -key "${SYS_CA_KEY}" \
  -days 365 -out "${SYS_CA_CERT}" \
  -subj "/CN=log-cache-ca" 2>/dev/null > /dev/null

for CN in "log-cache" "log-cache-syslog" "log-cache-metrics" "log-cache-gateway"; do
  openssl genrsa -out "${SYSTEM_PATH}/${CN}.key" 2048 2>/dev/null > /dev/null
  openssl req -new -key "${SYSTEM_PATH}/${CN}.key" -out "${SYSTEM_PATH}/${CN}.csr" \
    -subj "/CN=${CN}"  2>/dev/null > /dev/null

  openssl x509 -req -in "${SYSTEM_PATH}/${CN}.csr" -CA "${SYS_CA_CERT}" -CAkey "${SYS_CA_KEY}" -CAcreateserial -out "${SYSTEM_PATH}/${CN}.crt" \
      -extfile <(printf "extendedKeyUsage = 1.3.6.1.5.5.7.3.2,1.3.6.1.5.5.7.3.1") \
      -days 365 2>/dev/null > /dev/null
done

cat <<EOF
#@data/values
#! Original Certs/Keys can be found in ${CERT_PATH}
---
system_certificate:
  #! This certificates and keys are base64 encoded and should be valid for *.system.cf.example.com
  crt: &crt $( base64 < "${SSL_CERT}" | tr -d '\n' )
  key: &key $( base64 < "${SSL_KEY}" | tr -d '\n' )
  ca: $( base64 < "${CA_CERT}" | tr -d '\n' )

log_cache_ca:
  crt: $( base64 < "${SYS_CA_CERT}" | tr -d '\n' )
  key: $( base64 < "${SYS_CA_KEY}" | tr -d '\n' )

log_cache:
  crt: $( base64 < "${SYSTEM_PATH}/log-cache.crt" | tr -d '\n' )
  key: $( base64 < "${SYSTEM_PATH}/log-cache.key" | tr -d '\n' )

log_cache_metrics:
  crt: $( base64 < "${SYSTEM_PATH}/log-cache-metrics.crt" | tr -d '\n' )
  key: $( base64 < "${SYSTEM_PATH}/log-cache-metrics.key" | tr -d '\n' )

log_cache_gateway:
  crt: $( base64 < "${SYSTEM_PATH}/log-cache-gateway.crt" | tr -d '\n' )
  key: $( base64 < "${SYSTEM_PATH}/log-cache-gateway.key" | tr -d '\n' )

log_cache_syslog:
  crt: $( base64 < "${SYSTEM_PATH}/log-cache-syslog.crt" | tr -d '\n' )
  key: $( base64 < "${SYSTEM_PATH}/log-cache-syslog.key" | tr -d '\n' )

uaa:
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
