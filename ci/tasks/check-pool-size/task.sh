#!/bin/bash
set -eu

ready_pool_name="k8s-dev/ready"
pool_dir="pool-repo"

ready_count="$(find "${pool_dir}/${ready_pool_name}/unclaimed" -not -path '*/\.*' -type f | wc -l)"
echo "Unclaimed ready envs: ${ready_count}"

if [[ "${ready_count}" -lt "${POOL_SIZE_BUFFER_TARGET}" ]]; then
    echo "Fewer than ${POOL_SIZE_BUFFER_TARGET} envs are currently ready, going to trigger creation..."
    exit 1
else
    echo "Minimum pool size of ${POOL_SIZE_BUFFER_TARGET} satisfied."
    exit 0
fi
