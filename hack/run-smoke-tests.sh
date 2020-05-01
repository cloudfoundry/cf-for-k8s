#!/usr/bin/env sh

# This is a hack! see https://github.com/cloudfoundry/cf-for-k8s/blob/develop/hack/README.md

set -eu

echo "WARNING: The hack scripts are intended for development of cf-for-k8s. 
They are not officially supported product bits.  Their interface and behavior
may change at any time without notice." 1>&2

cd "$(dirname $0)/../tests/smoke"
ginkgo -v -r ./
