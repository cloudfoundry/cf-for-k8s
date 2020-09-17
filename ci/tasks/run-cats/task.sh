#!/bin/bash
set -eu

CONFIG_DIR="$(pwd)/config"
mkdir -p ${CONFIG_DIR}
CATS_CONFIG_FILE="${CONFIG_DIR}/cats_config.json"

DNS_DOMAIN=$(cat env-metadata/dns-domain.txt)
CF_ADMIN_PASSWORD="$(cat env-metadata/cf-admin-password.txt)"

set +x
echo '{}' | jq \
--arg cf_api_url "api.${DNS_DOMAIN}" \
--arg cf_apps_url "apps.${DNS_DOMAIN}" \
--arg cf_admin_password "${CF_ADMIN_PASSWORD}" \
--arg cf_push_timeout "${CF_PUSH_TIMEOUT}" \
--arg default_timeout "${DEFAULT_TIMEOUT}" \
--arg skip_ssl_validation "${SKIP_SSL_VALIDATION}" \
--arg include_apps "${INCLUDE_APPS}" \
--arg include_backend_compatability "${INCLUDE_BACKEND_COMPATABILITY}" \
--arg include_deployments "${INCLUDE_DEPLOYMENTS}" \
--arg include_detect "${INCLUDE_DETECT}" \
--arg include_docker "${INCLUDE_DOCKER}" \
--arg include_internet_dependent "${INCLUDE_INTERNET_DEPENDENT}" \
--arg include_docker_registry "${INCLUDE_DOCKER_REGISTRY}" \
--arg include_route_services "${INCLUDE_ROUTE_SERVICES}" \
--arg include_routing "${INCLUDE_ROUTING}" \
--arg include_service_discovery "${INCLUDE_SERVICE_DISCOVERY}" \
--arg include_service_instance_sharing "${INCLUDE_SERVICE_INSTANCE_SHARING}" \
--arg include_services "${INCLUDE_SERVICES}" \
--arg include_tasks "${INCLUDE_TASKS}" \
--arg include_v3 "${INCLUDE_V3}" \
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
  "ruby_buildpack_name": "paketo-community/ruby",
  "python_buildpack_name": "paketo-community/python",
  "go_buildpack_name": "paketo-buildpacks/go",
  "java_buildpack_name": "paketo-buildpacks/java",
  "nodejs_buildpack_name": "paketo-buildpacks/nodejs",
  "php_buildpack_name": "paketo-buildpacks/php",
  "binary_buildpack_name": "paketo-buildpacks/procfile"
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
  # As of 2020-08-02, we're seeing CATS failures when using >6 nodes
  # CATS run time looks like
  # nodes | run time
  #     1 | 47min
  #     3 | 17min
  #     6 | 11min
  #    12 | fails

popd
