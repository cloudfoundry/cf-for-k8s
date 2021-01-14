#!/bin/bash

set -eu -o pipefail

function get_image_digest_for_resource () {
  pushd "$1" >/dev/null
    cat digest
  popd >/dev/null
}

CAPI_IMAGE="cloudfoundry/cloud-controller-ng@$(get_image_digest_for_resource capi-docker-image)"
NGINX_IMAGE="cloudfoundry/capi-nginx@$(get_image_digest_for_resource nginx-docker-image)"
CONTROLLERS_IMAGE="cloudfoundry/cf-api-controllers@$(get_image_digest_for_resource cf-api-controllers-docker-image)"
REGISTRY_BUDDY_IMAGE="cloudfoundry/cf-api-package-registry-buddy@$(get_image_digest_for_resource registry-buddy-docker-image)"

function bump_image_references() {
    cat <<- EOF > "${PWD}/update-images.yml"
---
- type: replace
  path: /images/ccng
  value: ${CAPI_IMAGE}
- type: replace
  path: /images/nginx
  value: ${NGINX_IMAGE}
- type: replace
  path: /images/cf_api_controllers
  value: ${CONTROLLERS_IMAGE}
- type: replace
  path: /images/registry_buddy
  value: ${REGISTRY_BUDDY_IMAGE}
EOF

    pushd "capi-k8s-release"
      bosh interpolate values/images.yml -o "../update-images.yml" > values-int.yml

      echo "#@data/values" > values/images.yml
      echo "---" >> values/images.yml
      cat values-int.yml >> values/images.yml
    popd
}

function make_git_commit() {
    shopt -s dotglob

    # these need to be exported so generate-shortlog can find the appropriate source code
    export CCNG_DIR="cloud_controller_ng"
    export CF_API_CONTROLLERS_DIR="cf-api-controllers"
    export REGISTRY_BUDDY_DIR="registry-buddy"
    export NGINX_DIR="capi-nginx"
    ./capi-k8s-release/scripts/generate-shortlog.sh
    SHORTLOG="$(./capi-k8s-release/scripts/generate-shortlog.sh)"

    pushd "capi-k8s-release"
      git config user.name "${GIT_COMMIT_USERNAME}"
      git config user.email "${GIT_COMMIT_EMAIL}"
      git add values/images.yml

      # dont make a commit if there aren't new images
      if ! git diff --cached --exit-code; then
        echo "committing!"
        git commit -F <(echo "${SHORTLOG}")
      else
        echo "no changes to images, not bothering with a commit"
      fi
    popd

    cp -R "capi-k8s-release/." "updated-capi-k8s-release"
}

bump_image_references
make_git_commit
