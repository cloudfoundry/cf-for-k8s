#!/bin/bash
set -eu

building_pool_name="k8s-dev/building"
ready_pool_name="k8s-dev/ready"
pool_dir="pool-repo"

ready_count="$(find "${pool_dir}/${ready_pool_name}/unclaimed" -not -path '*/\.*' -type f | wc -l)"
echo "Unclaimed ready envs: ${ready_count}"
building_count="$(find "${pool_dir}/${building_pool_name}" -not -path '*/\.*' -type f | wc -l)"
echo "Building envs: ${building_count}"

env_count=$((ready_count + building_count))
echo "Total ready + building count: ${env_count}"

if [[ "${env_count}" -lt "${POOL_SIZE_BUFFER_TARGET}" ]]; then
    echo "Fewer than ${POOL_SIZE_BUFFER_TARGET} envs, going to trigger creation..."
    exit 1
else
    echo "Minimum pool size of ${POOL_SIZE_BUFFER_TARGET} satisfied."
    exit 0
fi
