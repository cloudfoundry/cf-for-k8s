#! /bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function generate_kbld_config() {
  local kbld_config_path="${1}"

  local source_path
  source_path="${SCRIPT_DIR}/sources"

  pushd "${source_path}" > /dev/null
    local git_ref
    git_ref=$(git rev-parse HEAD)
  popd > /dev/null

  echo "Creating Statsd exporter kbld config with ytt..."
  local kbld_config_values
  kbld_config_values=$(cat <<EOF
#@data/values
---
git_ref: ${git_ref}
git_url: https://github.com/prometheus/statsd_exporter
EOF
)

  echo "${kbld_config_values}" | ytt -f "${SCRIPT_DIR}/kbld.yml" -f - > "${kbld_config_path}"
}

function main() {
  local kbld_config_path="${1}"

  generate_kbld_config "${kbld_config_path}"
}

main "$@"
