#!/usr/bin/env bash

set -euo pipefail

function main() {
    local cwd="$1"

    local release_candidate_version
    release_candidate_version="v$(cat cf-for-k8s-rc-version/version)"

    local last_release_version
    last_release_version=$(curl --silent "https://api.github.com/repos/cloudfoundry/cf-for-k8s/releases/latest" | jq -r .tag_name)

    echo "Checking values interface for ${last_release_version} ---> ${release_candidate_version}"

    pushd cf-for-k8s-last-release > /dev/null
      cp ./sample-cf-install-values.yml ${cwd}/prev-release-sample-values.yml
      ./hack/generate-values.sh -d wingdang-foobrizzle > ${cwd}/wingdang-foobrizzle-values.yml
    popd > /dev/null

    pushd cf-for-k8s-rc > /dev/null
      ytt -f config/ -f ${cwd}/wingdang-foobrizzle-values.yml -f ${cwd}/prev-release-sample-values.yml > /dev/null
    popd > /dev/null
}

main "${PWD}"