#!/usr/bin/env bash

set -euo pipefail

function get_merged_prs() {
  local github_api_user="$1"
  local github_api_token="$2"
  local last_release_version="$3"
  local release_candidate_version="$4"

  for number in $(git log --pretty=oneline "${last_release_version}...${release_candidate_version}" | grep "Merge pull request" | awk '{print $5}' | sed 's/#//' | sort -n); do
    title=$(curl -s -u "${github_api_user}:${github_api_token}" "https://api.github.com/repos/cloudfoundry/cf-for-k8s/pulls/${number}" | jq -r '.title')
    url=$(curl -s -u "${github_api_user}:${github_api_token}" "https://api.github.com/repos/cloudfoundry/cf-for-k8s/pulls/${number}" | jq -r '.html_url')
    echo "- ${title} [#${number}](${url})"
  done
}

function main() {
  local cwd="$1"

  local release_candidate_version
  release_candidate_version="v$(cat cf-for-k8s-rc-version/version)"

  local last_release_version
  last_release_version="v$(cat cf-for-k8s-last-release/version)"

  pushd cf-for-k8s-rc > /dev/null
    echo "v${release_candidate_version}" > "${cwd}/release-notes/name.txt"
    cat <<EOT > "${cwd}/release-notes/body.txt"
## Notices

## Highlights

## Scale Test Results

## Configuration changes

## PRs Merged
$(get_merged_prs "${GITHUB_API_USER}" "${GITHUB_API_TOKEN}" "${last_release_version}" "${release_candidate_version}")

## Issues Closed

## Release Updates

| Release | Old Version | New Version |
| ------- | ----------- | ----------- |

## Contributors
$(git log --format='%aN' "${last_release_version}...HEAD" | sort -u)
EOT
  popd > /dev/null
}

main "${PWD}"
