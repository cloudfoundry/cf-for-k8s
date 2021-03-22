#!/usr/bin/env bash

set -euo pipefail

function write_release_name() {
   mkdir -p release-text
   version=$(cat version/version)

   echo "v${version}" > release-text/name
}

function write_release_body() {
   tmp_dir=$(mktemp -d)

   # Generate git diff
   pushd cf-k8s-networking > /dev/null
     from_ref=$(git tag --sort=version:refname | egrep "^v[0-9]+\.[0-9]+\.[0-9]+$" | tail -2 | head -1)
     to_ref=$(git tag --sort=version:refname | egrep "^v[0-9]+\.[0-9]+\.[0-9]+$" | tail -1)

     # During ship-what job we want to compare version since last tag. Since
     # the new version tag hasn't been committed we can key off that to
     # understand if we are in ship-what
     if [[ "${to_ref}" != "v${version}" ]]; then
        from_ref=$(git tag --sort=version:refname | egrep "^v[0-9]+\.[0-9]+\.[0-9]+$" | tail -1)
        to_ref="HEAD"
     fi

     diff_string="${from_ref}...${to_ref}"
     echo "comparing ${diff_string}:"
     git log "${diff_string}" | { egrep -o '\[\#([0-9]+)' || true; } | cut -d# -f2 | sort | uniq > "${tmp_dir}/stories.raw"
   popd > /dev/null

   # Iterate through the found story links
   while read -r story_id
   do
     curl -s "https://www.pivotaltracker.com/services/v5/stories/${story_id}"
   done < "${tmp_dir}/stories.raw" > "${tmp_dir}/stories.json"

   cat "${tmp_dir}/stories.json" | \
      jq -r 'select(.current_state == "accepted") | "- ["+.name+"]("+.url+")"' \
      > release-text/body.md
}

function main() {
   write_release_name
   write_release_body

   cat release-text/body.md
}

main
