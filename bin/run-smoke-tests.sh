#!/bin/bash

set -eux -o pipefail

pushd "$(dirname $0)/../tests/smoke"
  ginkgo -v -r -race ./
popd
