#!/usr/bin/env bash

set -e

BUILD_IMAGE_SHA=$(cat build-image/digest)
RUN_IMAGE_SHA=$(cat run-image/digest)

pushd cf-for-k8s-develop
  sed -i -e "s|^    image: \"gcr.io/paketo-buildpacks/build@.*\"$|    image: \"gcr.io/paketo-buildpacks/build@${BUILD_IMAGE_SHA}\"| w /dev/stdout" config/kpack/default-buildpacks.yml
  sed -i -e "s|^    image: \"gcr.io/paketo-buildpacks/run@.*\"$|    image: \"gcr.io/paketo-buildpacks/run@${RUN_IMAGE_SHA}\"| w /dev/stdout" config/kpack/default-buildpacks.yml

  git config user.email "cf-release-integration@pivotal.io"
  git config user.name "relint-ci"
  git add .

  git diff-index --quiet HEAD || git commit -m "Autobump stack images"
popd
mkdir -p cf-for-k8s-bumped
cp -R cf-for-k8s-develop/. cf-for-k8s-bumped/
