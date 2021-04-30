#! /bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function generate_kbld_config() {
  local kbld_config_path="${1}"

  local source_path
  source_path="${SCRIPT_DIR}/../../sources/cf-k8s-logging-fluent"

  pushd "${source_path}" > /dev/null
    local git_ref
    git_ref="v$(grep FLB_VERSION fluent-bit/Dockerfile | cut -d ' ' -f 3 | head -n 1)"
  popd > /dev/null

  echo "Creating CAPI K8s release kbld config with ytt..."
  local kbld_config_values
  kbld_config_values=$(cat <<EOF
#@data/values
---
git_ref: ${git_ref}
git_url: https://github.com/fluent/fluent-bit
EOF
)

  echo "${kbld_config_values}" | ytt -f "${SCRIPT_DIR}/kbld.yml" -f - > "${kbld_config_path}"
}

function main() {
  local kbld_config_path="${1}"

  generate_kbld_config "${kbld_config_path}"
}

main "$@"
