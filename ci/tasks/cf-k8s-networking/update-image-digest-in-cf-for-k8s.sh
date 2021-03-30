#!/usr/bin/env bash
set -euo pipefail

# ENV
: "${COMPONENT_NAME:?}"
: "${TARGET_FILE:?}"

pushd image-resource > /dev/null
  digest="$(cat digest)"
popd

pushd cf-for-k8s-develop
  sed -r -i "s|(cloudfoundry/${COMPONENT_NAME})@sha256:[a-f0-9]+|\1@${digest}|" "${TARGET_FILE}"
  ./build/istio/build.sh

  git config user.name "${GIT_COMMIT_USERNAME}"
  git config user.email "${GIT_COMMIT_EMAIL}"

  if [[ -n $(git status --porcelain) ]]; then
      echo "changes detected, will commit..."
      git add "${TARGET_FILE}"
      git add "config/istio/istio-generated"
      git commit -m "Update ${COMPONENT_NAME} image digest to ${digest}"

      git log -1 --color | cat
  else
      echo "no changes in repo, no commit necessary"
  fi
popd

# include dot files in * globing
shopt -s dotglob
cp -r cf-for-k8s-develop/* cf-for-k8s-modified/
