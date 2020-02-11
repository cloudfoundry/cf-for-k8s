#!/usr/bin/env sh

set -eu

cd "`dirname $0`/../tests/smoke"
ginkgo -v -r -race ./
