#! /bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function generate_kbld_config() {
  local kbld_config_path="${1}"

  local source_path
  source_path="${SCRIPT_DIR}/../../sources/eirini"

  pushd "${source_path}" > /dev/null
    local git_sha
    git_sha=$(git rev-parse HEAD)
  popd > /dev/null

  echo "Creating Eirini kbld config with ytt"
  local kbld_config_values
  kbld_config_values=$(cat <<EOF
#@data/values
---
git_sha: ${git_sha}
EOF
)

  echo "${kbld_config_values}" | ytt -f "${SCRIPT_DIR}/kbld.yml" -f - > "${kbld_config_path}"
}

function main() {
  local kbld_config_path="${1}"

  generate_kbld_config "${kbld_config_path}"
}

main "$@"
