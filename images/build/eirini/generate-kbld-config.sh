#! /bin/bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function generate_kbld_config() {
  local kbld_config_path="${1}"

  local eirini_source_path
  eirini_source_path="${SCRIPT_DIR}/../../sources/eirini"

  pushd "${eirini_source_path}" > /dev/null
    local git_sha
    git_sha=$(git rev-parse HEAD)
  popd > /dev/null

  echo "Creating kbld config with ytt"
  local kbld_config_values
  kbld_config_values=$(cat <<EOF
#@data/values
---
eirini:
  git_sha: ${git_sha}
  source:
    path: ${eirini_source_path}
EOF
)

  local kbld_config
  echo "${kbld_config_values}" | ytt -f "${SCRIPT_DIR}/kbld.yml" -f - > ${kbld_config_path}
}

function main() {
  local kbld_config_path="${1}"

  generate_kbld_config "${kbld_config_path}"
}

main "$@"
