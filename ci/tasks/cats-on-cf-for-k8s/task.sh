#!/bin/bash
set -eu

DIR=$(pwd)

DNS_DOMAIN=$(cat env-metadata/dns-domain.txt)
CF_ADMIN_PASSWORD="$(cat env-metadata/cf-admin-password.txt)"

mkdir "${DIR}/config"

set +x
echo '{}' | jq \
--arg cf_api_url "api.${DNS_DOMAIN}" \
--arg cf_apps_url "apps.${DNS_DOMAIN}" \
--arg cf_admin_password "${CF_ADMIN_PASSWORD}" \
'{
  "api": $cf_api_url,
  "admin_user": "admin",
  "admin_password": $cf_admin_password,
  "apps_domain": $cf_apps_url,
  "skip_ssl_validation": true,
  "timeout_scale": 1,
  "include_apps": true,
  "include_backend_compatibility": false,
  "include_deployments": false,
  "include_detect": false,
  "include_docker": false,
  "include_internet_dependent": false,
  "include_private_docker_registry": false,
  "include_route_services": false,
  "include_routing": false,
  "include_service_discovery": false,
  "include_service_instance_sharing": false,
  "include_services": false,
  "include_tasks": false,
  "include_v3": false,
  "infrastructure": "kubernetes",
  "ruby_buildpack_name": "paketo-community/ruby",
  "python_buildpack_name": "paketo-community/python",
  "go_buildpack_name": "paketo-buildpacks/go",
  "java_buildpack_name": "paketo-buildpacks/java",
  "nodejs_buildpack_name": "paketo-buildpacks/nodejs",
  "php_buildpack_name": "paketo-buildpacks/php",
  "binary_buildpack_name": "paketo-buildpacks/procfile"
}' > "${DIR}/config/cats_config.json"

set -x
pushd cf-acceptance-tests
export CONFIG="${DIR}/config/cats_config.json"
./bin/test
popd