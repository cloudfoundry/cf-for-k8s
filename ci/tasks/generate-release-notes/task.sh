#!/usr/bin/env bash

set -euo pipefail

function get_merged_prs() {
  local github_api_user="$1"
  local github_api_token="$2"
  local last_release_version="$3"
  local release_candidate_version="$4"

  prev_release_iso_date=$(git show "${last_release_version}" --date=format:'%Y-%m-%dT%H:%M:%SZ' | grep Date: | awk '{print $2}')
  rc_tag_url=$(curl -s -u "${github_api_user}:${github_api_token}" https://api.github.com/repos/cloudfoundry/cf-for-k8s/git/ref/tags/$release_candidate_version | jq -r .object.url)
  rc_tag_iso_date=$(curl -s -u "${github_api_user}:${github_api_token}" $rc_tag_url | jq -r .tagger.date)
  pulls=$(curl -s -u "${github_api_user}:${github_api_token}" https://api.github.com/repos/cloudfoundry/cf-for-k8s/pulls?since=$prev_release_iso_date\&state=closed | jq --arg START "${prev_release_iso_date}"  --arg END "${rc_tag_iso_date}" '[.[] | select((.merged_at >= $START) and (.merged_at < $END))]')

  IFS=$'\n'
  for pull in $(echo "${pulls}" | jq -rc '.[] | {number, title, html_url}'); do
    echo "${pull}" | jq -r '"- " + .title + " [" + (.number|tostring) + "](" + .html_url + ")"'
  done
}

function get_closed_issues() {
  local github_api_user="$1"
  local github_api_token="$2"
  local last_release_version="$3"
  local release_candidate_version="$4"

  prev_release_iso_date=$(git show "${last_release_version}" --date=format:'%Y-%m-%dT%H:%M:%SZ' | grep Date: | awk '{print $2}')
  rc_tag_url=$(curl -s -u "${github_api_user}:${github_api_token}" https://api.github.com/repos/cloudfoundry/cf-for-k8s/git/ref/tags/$release_candidate_version | jq -r .object.url)
  rc_tag_iso_date=$(curl -s -u "${github_api_user}:${github_api_token}" $rc_tag_url | jq -r .tagger.date)
  issues=$(curl -s -u "${github_api_user}:${github_api_token}" https://api.github.com/repos/cloudfoundry/cf-for-k8s/issues?since=$prev_release_iso_date\&state=closed | jq --arg START "${prev_release_iso_date}"  --arg END "${rc_tag_iso_date}" '[.[] | select((.closed_at >= $START) and (.closed_at < $END)) | select(.pull_request == null)]')

  IFS=$'\n'
  for issue in $(echo "${issues}" | jq -rc '.[] | {number, title, html_url}'); do
    echo "${issue}" | jq -r '"- " + .title + " [" + (.number|tostring) + "](" + .html_url + ")"'
  done
}

function get_component_ref_from_vendir() {
  local line_to_find="$1"
  local vendir_path="$2"

  grep -A 6 "${line_to_find}" ${vendir_path} | grep -E "ref|tag" | head -n1 | awk '{ print $2 }'
}

function append_component_line() {
  local component_name="$1"
  local line_to_find="$2"

  from_sha=$(get_component_ref_from_vendir "${line_to_find}" cf-for-k8s-last-release/vendir.yml)
  to_sha=$(get_component_ref_from_vendir "${line_to_find}" cf-for-k8s-rc/vendir.yml)
  if [[ -z ${from_sha} ]] || [[ -z ${to_sha} ]]; then
    echo "ERROR: Parsing of vendir version for component ${component_name} failed"
    echo "exit 1"
  elif [[ ${from_sha} == ${to_sha} ]]; then
    echo "Before and after SHAs/refs match - no need to add to table"
  else
    if [[ "${component_name}" == "CF API" ]]; then
      from_sha=$(echo "${from_sha}" | cut -c 1-7)
      short_to_sha=$(echo "${to_sha}" | cut -c 1-7)
      to_hyperlink="[${short_to_sha}](https://github.com/cloudfoundry/capi-k8s-release/commit/${to_sha})"
    elif [[ "${component_name}" == "Networking" ]]; then
      from_sha=$(echo "${from_sha}" | cut -c 1-7)
      short_to_sha=$(echo "${to_sha}" | cut -c 1-7)
      to_hyperlink="[${short_to_sha}](https://github.com/cloudfoundry/cf-k8s-networking/commit/${to_sha})"
    elif [[ "${component_name}" == "Eirini" ]]; then
      to_hyperlink="[${to_sha}](https://github.com/cloudfoundry-incubator/eirini-release/releases/tag/${to_sha})"
    elif [[ "${component_name}" == "Kpack" ]]; then
      to_hyperlink="[${to_sha}](https://github.com/pivotal/kpack/releases/tag/${to_sha})"
    elif [[ "${component_name}" == "Logging" ]]; then
      to_hyperlink="[${to_sha}](https://github.com/cloudfoundry/cf-k8s-logging/releases/tag/${to_sha})"
    elif [[ "${component_name}" == "Metrics" ]]; then
      to_hyperlink="[${to_sha}](https://github.com/cloudfoundry/metric-proxy/releases/tag/${to_sha})"
    elif [[ "${component_name}" == "QuarksSecret" ]]; then
      to_hyperlink="[${to_sha}](https://github.com/cloudfoundry-incubator/quarks-secret/releases/tag/${to_sha})"
    elif [[ "${component_name}" == "UAA" ]]; then
      to_hyperlink="[${to_sha}](https://github.com/cloudfoundry/uaa-k8s-release/commit/${to_sha})"
    else
      echo "ERROR: Unrecognized component name: ${component_name}"
      ex
    fi
    release_table_text+="\n| ${component_name} | ${from_sha} | ${to_hyperlink} |"
  fi
}

function append_yaml_line() {
  component_name=$1
  release_url=$2
  filter=$3
  file=$4
  from_ver=$(yq -r $filter cf-for-k8s-last-release/$file)
  to_ver=$(yq -r $filter cf-for-k8s-rc/$file)
  if [ "$from_ver" != "$to_ver" ]; then
    release_table_text+="\n| ${component_name} | ${from_ver} | [${to_ver}](${release_url}/${to_ver}) |"
  fi
}

function build_component_bump_table_content() {
  release_table_text="
| Release | Old Version | New Version |
| ------- | ----------- | ----------- |"

  append_component_line "CF API" "path: config/capi/_ytt_lib/capi-k8s-release"
  append_component_line "Eirini" "path: build/eirini/_vendir"
  append_yaml_line "Istio" "https://github.com/istio/istio/releases/tag" ".istio_version" "build/istio/values.yaml"
  append_component_line "Kpack" "path: config/kpack/_ytt_lib/kpack"
  append_component_line "Logging" "path: config/logging/_ytt_lib/cf-k8s-logging"
  append_component_line "Metrics" "path: config/metrics/_ytt_lib/metric-proxy"
  append_component_line "Networking" "path: config/networking/_ytt_lib/cf-k8s-networking"
  append_component_line "QuarksSecret" "path: build/quarks-secret/_vendir"
  append_component_line "UAA" "path: config/uaa/_ytt_lib/uaa-k8s-release"
  release_table_text+="\n"

}

function main() {
  local cwd="$1"

  local release_candidate_version
  release_candidate_version="v$(cat cf-for-k8s-rc-version/version)"

  local last_release_version
  last_release_version=$(curl --silent "https://api.github.com/repos/cloudfoundry/cf-for-k8s/releases/latest" | jq -r .tag_name)

  local release_version
  release_version=$(echo "$release_candidate_version" | sed -r 's/^(v[0-9].[0-9].[0-9]).*/\1/g')

  build_component_bump_table_content

  pushd cf-for-k8s-rc > /dev/null
    echo "${release_version}" > "${cwd}/release-notes/name.txt"
    cat <<EOT > "${cwd}/release-notes/body.txt"
## Notices
<include changes to values file>

## Highlights

## Scale Test Results

## Configuration changes

## PRs Merged
$(get_merged_prs "${GITHUB_API_USER}" "${GITHUB_API_TOKEN}" "${last_release_version}" "${release_candidate_version}")

## Issues Closed
$(get_closed_issues "${GITHUB_API_USER}" "${GITHUB_API_TOKEN}" "${last_release_version}" "${release_candidate_version}")

## Release Updates

$(printf "${release_table_text}")

## Contributors
$(git log --format='%aN' "${last_release_version}...HEAD" | sort -u)
EOT
  popd > /dev/null

  cat "${cwd}/release-notes/body.txt"
}

main "${PWD}"
