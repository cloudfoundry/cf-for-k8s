#!/usr/bin/env bash

set -euo pipefail

function parse_git_source() {
  pushd source-repo >/dev/null
    git remote get-url origin
  popd >/dev/null
}

# Manually parse revision info from input git resource
git_ref=$(cat source-repo/.git/ref)
git_source=$(parse_git_source)

cat <<EOF > labels/oci-image-labels
org.opencontainers.image.revision=${git_ref}
org.opencontainers.image.source=${git_source}
EOF

cat labels/oci-image-labels
