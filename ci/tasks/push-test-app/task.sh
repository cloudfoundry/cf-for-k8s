#!/bin/bash
set -euc

DNS_DOMAIN=$(cat env-metadata/dns-domain.txt)
cf api api.${DNS_DOMAIN} --skip-ssl-validation
cf auth admin "$(cat env-metadata/cf-admin-password.txt)"
cf create-org org
cf target -o org
cf create-space space
cf target -o org -s space

cf push ${APP_NAME} -p cf-for-k8s-repo/tests/smoke/assets/test-node-app
