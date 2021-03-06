#!/usr/bin/env bash

set -euo pipefail

function main() {
  local cwd="$1"

  local release_candidate_version
  release_candidate_version="v$(cat cf-for-k8s-version/version)"

cat <<EOT > "${cwd}/tag-annotation/body.txt"
Tagging version: ${release_candidate_version}
EOT
}

main "${PWD}"
