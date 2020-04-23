#!/bin/bash

set -exu

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
    if [[ $dir = "minio" ]] ; then
      # Ignore the change to the `rollme` random value
      minio_rendered_file="$DIR/config/_ytt_lib/minio/rendered.yml"
      if [[ $(git diff --unified=0 "$minio_rendered_file" | egrep "^(\+|-) " | grep -v rollme | wc -l) == 0 ]] ; then
        git checkout "$minio_rendered_file"
      fi
    fi
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

