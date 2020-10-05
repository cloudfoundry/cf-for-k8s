#!/bin/bash
set -eu

DNS_DOMAIN=$(cat env-metadata/dns-domain.txt)
export SMOKE_TEST_API_ENDPOINT="https://api.${DNS_DOMAIN}"
export SMOKE_TEST_APPS_DOMAIN="apps.${DNS_DOMAIN}"
export SMOKE_TEST_USERNAME=admin
export SMOKE_TEST_PASSWORD=$(cat env-metadata/cf-admin-password.txt)

echo "Running smoke tests with skip_ssl set to: ${SMOKE_TEST_SKIP_SSL}"

if [[ ${SMOKE_TEST_SKIP_SSL} != "true" ]]; then
  echo "Updating trust store by appending default ca to ca-certificates.crt"
  cat env-metadata/default_ca.ca >> /etc/ssl/certs/ca-certificates.crt
fi

cf-for-k8s/hack/run-smoke-tests.sh
