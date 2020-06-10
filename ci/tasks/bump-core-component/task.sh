#!/bin/bash -eux

TAG=$(cat release/tag)
pushd cf-for-k8s-develop > /dev/null
  CURR_TAG_LINE=$(grep -A 20 "path: .*${REPO_NAME}" vendir.yml | grep tag | head -n1 | awk '{$1=$1;print}')
  sed "s/${CURR_TAG_LINE}/tag: ${TAG}/g" vendir.yml > /tmp/vendir.yml && mv /tmp/vendir.yml vendir.yml

  vendir sync

  git config user.email "cf-release-integration@pivotal.io"
  git config user.name "relint-ci"
  git add .
  git commit -m "Bump ${REPO_NAME} to ${TAG}"

popd > /dev/null

cp -r cf-for-k8s-develop/. cf-for-k8s-bump
