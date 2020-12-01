#!/usr/bin/env bash

set -eu

# for our built dependencies (eirini, istio, minio, postgres)
# make sure that PRs that updated the vendir.yml were properly
# synced to cf-for-k8s. Specifically that vendir.lock reflects
# the new dependency version and that the `build` and `config` directories
# contains an updated version of the dependency.

# ENV
: "${REPO_DIR:?}"

HOMEDIR=$(dirname $(readlink -f "$0"))
cd "$REPO_DIR"
echo "Verifying vendir sync doesn't create new changes..."
vendir sync > /dev/null

set +e
git status
git add .
git --no-pager diff HEAD
set -e

git diff-index --quiet HEAD
echo "Successfully verified running 'vendir sync' did not create new changes"

DIR=$PWD
cd build
for dir in * ; do
  if [[ -d "$dir" ]] ; then
    cd $dir
    ./build.sh
    cd ..
  fi
done

set +e
git status
git add .
git --no-pager diff HEAD
set -e

git diff --unified=0 | grep '^[-+][^-+]' | awk -f "$HOMEDIR/ignore-moved-lines.awk"
echo "Successfully verified the build scripts did not create new changes"
