#!/usr/bin/env bash

set -eu

# Don't -o pipefail for this part
env_suffix=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)

echo "${CLUSTER_NAME}-${env_suffix}" > tf-vars/env-name.txt
cat <<EOT > tf-vars/input.tfvars
project = "${GCP_PROJECT_NAME}"
region = "${GCP_PROJECT_REGION}"
zone = "${GCP_PROJECT_ZONE}"
service_account_key = "$(echo ${SERVICE_ACCOUNT_JSON} | jq -c '.' | sed -e 's#"#\\"#g' -e 's#\\n#\\\\n#g')"
machine_type = "n1-standard-8"
EOT
