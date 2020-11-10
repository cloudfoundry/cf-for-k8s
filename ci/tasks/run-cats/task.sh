#!/bin/bash
set -eu

CONFIG_DIR="$(pwd)/config"
mkdir -p ${CONFIG_DIR}
CATS_CONFIG_FILE="${CONFIG_DIR}/cats_config.json"

if [[ -e env-metadata ]]; then
  DNS_DOMAIN=$(cat env-metadata/dns-domain.txt)
  CF_ADMIN_PASSWORD="$(cat env-metadata/cf-admin-password.txt)"

  CF_APPS_DOMAIN="apps.${DNS_DOMAIN}"
  CF_API_DOMAIN="api.${DNS_DOMAIN}"
fi

set +x
echo '{}' | jq \
--arg cf_api_url "${CF_API_DOMAIN}" \
--arg cf_apps_url "${CF_APPS_DOMAIN}" \
--arg cf_admin_password "${CF_ADMIN_PASSWORD}" \
--argjson cf_push_timeout "${CF_PUSH_TIMEOUT}" \
--argjson default_timeout "${DEFAULT_TIMEOUT}" \
--argjson skip_ssl_validation "${SKIP_SSL_VALIDATION}" \
--argjson include_apps "${INCLUDE_APPS}" \
--argjson include_backend_compatability "${INCLUDE_BACKEND_COMPATABILITY}" \
--argjson include_deployments "${INCLUDE_DEPLOYMENTS}" \
--argjson include_detect "${INCLUDE_DETECT}" \
--argjson include_docker "${INCLUDE_DOCKER}" \
--argjson include_internet_dependent "${INCLUDE_INTERNET_DEPENDENT}" \
--argjson include_docker_registry "${INCLUDE_DOCKER_REGISTRY}" \
--argjson include_route_services "${INCLUDE_ROUTE_SERVICES}" \
--argjson include_routing "${INCLUDE_ROUTING}" \
--argjson include_service_discovery "${INCLUDE_SERVICE_DISCOVERY}" \
--argjson include_service_instance_sharing "${INCLUDE_SERVICE_INSTANCE_SHARING}" \
--argjson include_services "${INCLUDE_SERVICES}" \
--argjson include_tasks "${INCLUDE_TASKS}" \
--argjson include_v3 "${INCLUDE_V3}" \
--arg ruby_buildpack "${RUBY_BUILDPACK}" \
--arg python_buildpack "${PYTHON_BUILDPACK}" \
--arg go_buildpack "${GO_BUILDPACK}" \
--arg java_buildpack "${JAVA_BUILDPACK}" \
--arg nodejs_buildpack "${NODEJS_BUILDPACK}" \
--arg php_buildpack "${PHP_BUILDPACK}" \
--arg binary_buildpack "${BINARY_BUILDPACK}" \
'{
  "api": $cf_api_url,
  "admin_user": "admin",
  "admin_password": $cf_admin_password,
  "apps_domain": $cf_apps_url,
  "cf_push_timeout": $cf_push_timeout,
  "default_timeout": $default_timeout,
  "skip_ssl_validation": $skip_ssl_validation,
  "timeout_scale": 1,
  "include_apps": $include_apps,
  "include_backend_compatibility": $include_backend_compatability,
  "include_deployments": $include_deployments,
  "include_detect": $include_detect,
  "include_docker": $include_docker,
  "include_internet_dependent": $include_internet_dependent,
  "include_private_docker_registry": $include_docker_registry,
  "include_route_services": $include_route_services,
  "include_routing": $include_routing,
  "include_service_discovery": $include_service_discovery,
  "include_service_instance_sharing": $include_service_instance_sharing,
  "include_services": $include_services,
  "include_tasks": $include_tasks,
  "include_v3": $include_v3,
  "infrastructure": "kubernetes",
  "ruby_buildpack_name": $ruby_buildpack,
  "python_buildpack_name": $python_buildpack,
  "go_buildpack_name": $go_buildpack,
  "java_buildpack_name": $java_buildpack,
  "nodejs_buildpack_name": $nodejs_buildpack,
  "php_buildpack_name": $php_buildpack,
  "binary_buildpack_name": $binary_buildpack
}' > "${CATS_CONFIG_FILE}"
# `cf_push_timeout` and `default_timeout` are set fairly arbitrarily

set -x
pushd cf-acceptance-tests
  export CONFIG="${CATS_CONFIG_FILE}"
  ./bin/test \
    -keepGoing \
    -randomizeAllSpecs \
    -flakeAttempts=${NUM_FLAKE_ATTEMPTS} \
    -nodes=${NUM_NODES}
  # Around 2020-08-02, we saw CATS failures when using >6 nodes.
  #
  # Proportional CATS run time looks like
  # nodes | run time
  #     6 | x minutes
  #     3 | 1.5x minutes
  #     1 | 4x minutes
  #
  # For current CATS runtime using GKE and 6 nodes, see:
  # https://release-integration.ci.cf-app.com/teams/main/pipelines/cf-for-k8s-main/jobs/run-cats

popd
