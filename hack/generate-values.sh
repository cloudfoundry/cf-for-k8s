#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage $(basename "$0") <domain>"
  exit 1
fi

password() {
  tr -dc '[:alnum:]' < /dev/urandom | head -c 32
}

## Usage: ./generate-values.sh <my-domain>
## where my-domain will be used as both the system domain and app domain.

DOMAIN=$1

cat <<EOF
#@data/values
---
system_domain: "${DOMAIN}"
app_domains:
#@overlay/append
- "${DOMAIN}"
cf_admin_password: "$(password)"

cf_blobstore:
  secret_key: "$(password)"

cf_db:
  admin_password: "$(password)"

capi:
  database:
    password: "$(password)"

uaa:
  database:
    password: "$(password)"
  admin_client_secret: "$(password)"

docker_registry:
  http_secret: "$(password)"
EOF
