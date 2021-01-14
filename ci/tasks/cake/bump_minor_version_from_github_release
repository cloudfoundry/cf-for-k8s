#!/usr/bin/env bash

set -euo pipefail

# borrowing this from: https://github.com/cloudflare/semver_bash
function semverParseInto() {
    local RE='[^0-9]*\([0-9]*\)[.]\([0-9]*\)[.]\([0-9]*\)\([0-9A-Za-z-]*\)'
    #MAJOR
    eval $2=`echo $1 | sed -e "s#$RE#\1#"`
    #MINOR
    eval $3=`echo $1 | sed -e "s#$RE#\2#"`
    #MINOR
    eval $4=`echo $1 | sed -e "s#$RE#\3#"`
    #SPECIAL
    eval $5=`echo $1 | sed -e "s#$RE#\4#"`
}

function bump_minor() {
    local input_version=$1
    echo "Input Version: ${input_version}" 1>&2

    local major=0
    local minor=0
    local patch=0
    local special=""

    semverParseInto "$input_version" major minor patch special

    output="$(echo "v$major.$((minor+1)).0")"
    echo "Bumped Version: $output" 1>&2
    echo "$output"
}

VERSION="$(cat github-release/tag)"
bump_minor "${VERSION}" > bumped-minor-version/version

