#!/bin/bash

set -eu

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../" && pwd )"

pushd "${workspace_dir}/cf-api-controllers/src/cf-api-controllers" >/dev/null
    make test
popd >/dev/null
