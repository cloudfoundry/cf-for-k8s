#!/bin/bash
set -euc

DNS_DOMAIN=$(cat env-metadata/dns-domain.txt)

#verify existing app still works
curl -k https://${APP_NAME}.apps.${DNS_DOMAIN}
echo "Confirmed that existing app is still available"

cf api api.${DNS_DOMAIN} --skip-ssl-validation
cf auth admin "$(cat env-metadata/cf-admin-password.txt)"
cf create-org org
cf target -o org
cf create-space space
cf target -o org -s space
cf push ${APP_NAME} -p cf-for-k8s-master/tests/smoke/assets/test-node-app
echo "re-push succeeded"

curl -k https://${APP_NAME}.apps.${DNS_DOMAIN}
echo "Confirmed that app is still available"
