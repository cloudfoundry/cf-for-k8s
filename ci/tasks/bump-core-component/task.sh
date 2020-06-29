#!/bin/bash -eux

if [[ "${GITHUB_RELEASE}" == "false" ]]; then
  pushd release > /dev/null
    TAG=$(git rev-parse HEAD)
  popd > /dev/null
else
  TAG=$(cat release/tag)
fi

pushd cf-for-k8s-develop > /dev/null
  if [[ "${VENDIR_GITHUB_RELEASE}" == "false" ]]; then
    # we believe we need the component teams to include the necessary files in their release assets
    # before we can switch to using a githubRelease in vendir.yml
    vendir_key="ref"
  else
    vendir_key="tag"
  fi

  CURR_TAG_LINE=$(grep -A 20 "path: .*${REPO_NAME}" vendir.yml | grep ${vendir_key} | head -n1 | awk '{$1=$1;print}')
  sed "s/${CURR_TAG_LINE}/${vendir_key}: ${TAG}/g" vendir.yml > /tmp/vendir.yml && mv /tmp/vendir.yml vendir.yml

  CURR_TAG=$(echo $CURR_TAG_LINE | awk '{print $2}')

  if [[ "${CURR_TAG}" != "${TAG}" ]]; then
    vendir sync

    if [[ -n "${BUILD_DIR}" ]]; then
      pushd "${BUILD_DIR}" > /dev/null
        ./build.sh
      popd > /dev/null
    fi

    git config user.email "cf-release-integration@pivotal.io"
    git config user.name "relint-ci"
    git add .
    git commit -m "Bump ${REPO_NAME} to ${TAG}"
  else
    echo "Tag ${CURR_TAG} has not changed. No update needed."
  fi
popd > /dev/null

cp -r cf-for-k8s-develop/. cf-for-k8s-bump
