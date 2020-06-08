#!/bin/bash
set -eu

DNS_DOMAIN=$(cat env-metadata/dns-domain.txt)

if ${VERIFY_EXISTING_APP}; then
    echo "Verify availability of existing app: ${APP_NAME}"
    curl -k --retry 6 --retry-connrefused ${APP_NAME}.apps.${DNS_DOMAIN}
    echo "Confirmed that existing app is still available"
fi

cf api api.${DNS_DOMAIN} --skip-ssl-validation
cf auth admin "$(cat env-metadata/cf-admin-password.txt)"
cf create-org org
cf target -o org
cf create-space space
cf target -o org -s space

echo "Pushing ${APP_NAME}"
cf push ${APP_NAME} -p cf-for-k8s-repo/tests/smoke/assets/test-node-app

echo "Verify availability of ${APP_NAME}"
curl -k https://${APP_NAME}.apps.${DNS_DOMAIN}
echo "Confirmed that app is available"
