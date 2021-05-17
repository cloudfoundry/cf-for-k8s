#!/bin/bash

set -eu

go get github.com/onsi/ginkgo/ginkgo
go install github.com/onsi/ginkgo/ginkgo

pushd "registry-buddy/src/registry-buddy" >/dev/null
     ginkgo -r -keepGoing -p -trace -randomizeAllSpecs -progress --race
popd >/dev/null
