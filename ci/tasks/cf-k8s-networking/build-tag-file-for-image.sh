#!/usr/bin/env bash

set -euo pipefail

pushd cf-k8s-networking > /dev/null
    git_sha="$(cat .git/ref)"
    branch_name="$(ls .git/refs/heads)"
popd

echo "${branch_name} ${git_sha}" > docker-info/tags
