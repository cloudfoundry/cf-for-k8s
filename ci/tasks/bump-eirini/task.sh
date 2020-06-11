#!/bin/bash -eux

TAG=$(cat eirini-release/tag)
pushd cf-for-k8s-develop > /dev/null
  CURR_TAG_LINE=$(grep -A 20 "path: build/eirini/_vendir" vendir.yml | grep tag | head -n1 | awk '{$1=$1;print}')
  sed "s/${CURR_TAG_LINE}/tag: ${TAG}/g" vendir.yml > /tmp/vendir.yml && mv /tmp/vendir.yml vendir.yml

  CURR_TAG=$(echo $CURR_TAG_LINE | awk '{print $2}')

  if [[ "${CURR_TAG}" != "${TAG}" ]]; then
    vendir sync

    pushd build/eirini > /dev/null
      ./build.sh
    popd > /dev/null
    git config user.email "cf-release-integration@pivotal.io"
    git config user.name "relint-ci"
    git add .
    git commit -m "Bump eirini to ${TAG}"
  else
    echo "Tag ${CURR_TAG} has not changed. No update needed."
  fi

popd > /dev/null

cp -r cf-for-k8s-develop/. cf-for-k8s-bump
