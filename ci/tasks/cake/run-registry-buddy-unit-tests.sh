#!/bin/bash

set -eu

# INPUTS
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
workspace_dir="$( cd "${script_dir}/../../../" && pwd )"

go get github.com/onsi/ginkgo/ginkgo
go install github.com/onsi/ginkgo/ginkgo

pushd "${workspace_dir}/registry-buddy/src/registry-buddy" >/dev/null
     ginkgo -r -keepGoing -p -trace -randomizeAllSpecs -progress --race
popd >/dev/null
