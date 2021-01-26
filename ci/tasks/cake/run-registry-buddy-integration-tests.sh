#!/bin/bash

set -euo pipefail

: "${REGISTRY_BASE_PATH:?}"
: "${REGISTRY_PASSWORD:?}"
: "${REGISTRY_USERNAME:?}"

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../" && pwd )"

go get github.com/onsi/ginkgo/ginkgo
go install github.com/onsi/ginkgo/ginkgo

pushd "${workspace_dir}/registry-buddy/src/registry-buddy" >/dev/null
     ginkgo -keepGoing -p -trace -randomizeAllSpecs -progress --race integration
popd >/dev/null
