#!/usr/bin/env bash

set -euo pipefail

function write_cats_config() {
    admin_password=$(cat env-metadata/cf-admin-password.txt)
    dns_domain=$(cat env-metadata/dns-domain.txt)
    mkdir -p integration-config
    cat <<- EOF > "integration-config/config.json"
{
   "api": "api.${dns_domain}",
   "admin_user": "admin",
   "admin_password": "${admin_password}",
   "apps_domain": "apps.${dns_domain}"
}
EOF
}

function main() {
    write_cats_config
}

main
