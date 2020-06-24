#!/bin/bash -eux

if [[ ${REPO_NAME} == "capi-k8s-release" ]]; then
  pushd release > /dev/null
    TAG=$(git rev-parse HEAD)
  popd > /dev/null
else
  TAG=$(cat release/tag)
fi

pushd cf-for-k8s-develop > /dev/null

  if [[ ${REPO_NAME} =~ ^(capi-k8s-release|uaa|cf-k8s-networking)$ ]]; then
    # we believe we need the component teams to include the necessary files in their release assets
    # before we can switch to using a githubRelease in vendir.yml
    vendir_key="ref"
  else
    vendir_key="tag"
  fi

  CURR_TAG_LINE=$(grep -A 20 "path: .*${REPO_NAME}" vendir.yml | grep ${vendir_key} | head -n1 | awk '{$1=$1;print}')
  OLD_TAG=$(echo $CURR_TAG_LINE | awk '{print $2}')
  sed "s/${CURR_TAG_LINE}/${vendir_key}: ${TAG}/g" vendir.yml > /tmp/vendir.yml && mv /tmp/vendir.yml vendir.yml

  if [[ "${OLD_TAG}" != "${TAG}" ]]; then
    vendir sync

    git config user.email "cf-release-integration@pivotal.io"
    git config user.name "relint-ci"
    git add .
    git commit -m "Bump ${REPO_NAME} to ${TAG}"
  else
    echo "Tag ${OLD_TAG} has not changed. No update needed."
  fi

popd > /dev/null

cp -r cf-for-k8s-develop/. cf-for-k8s-bump
