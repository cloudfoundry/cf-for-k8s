#!/usr/bin/env bash

set -eu

OUTPUT_DIR="generated-release"

# assumes semver resource is bumped before running
CAPI_K8S_VERSION="$(cat capi-k8s-release-version/version)"
CAPI_K8S_SHA="$(cat capi-k8s-release/.git/ref)"

# TODO: thoughts on name?
echo "CAPI K8s Release ${CAPI_K8S_VERSION}" > $OUTPUT_DIR/name
echo "${CAPI_K8S_VERSION}" > $OUTPUT_DIR/tag
echo "${CAPI_K8S_VERSION}" > $OUTPUT_DIR/version
echo "${CAPI_K8S_SHA}" > $OUTPUT_DIR/commitish
echo "${CAPI_K8S_SHA}" > $OUTPUT_DIR/commit_sha

pushd cloud_controller_ng
  SHA_CC=$(git rev-parse HEAD)
  # MIGRATIONS=($(git diff --diff-filter=A --name-only $PREVIOUS_SHA_CC db/migrations))
  pushd config
    VERSION_V2=$(cat version_v2)
    VERSION_V3=$(cat version)
    VERSION_BROKER_API=$(cat osbapi_version)
  popd
popd

# body == release notes
cat <<EOF > $OUTPUT_DIR/body
**Highlights**

**CC API Version: $VERSION_V2 and $VERSION_V3-rc**

**Service Broker API Version: [$VERSION_BROKER_API](https://github.com/openservicebrokerapi/servicebroker/blob/v$VERSION_BROKER_API/spec.md)**

### [CAPI K8s Release](https://github.com/cloudfoundry/capi-k8s-release/tree/$CAPI_K8S_SHA)

### [Cloud Controller](https://github.com/cloudfoundry/cloud_controller_ng/tree/$SHA_CC)

#### Cloud Controller Database Migrations

#### Pull Requests and Issues
EOF
