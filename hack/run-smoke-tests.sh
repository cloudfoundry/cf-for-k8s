#!/usr/bin/env sh

# This is a hack! see https://github.com/cloudfoundry/cf-for-k8s/blob/develop/hack/README.md

set -eu

cd "`dirname $0`/../tests/smoke"
ginkgo -v -r ./
