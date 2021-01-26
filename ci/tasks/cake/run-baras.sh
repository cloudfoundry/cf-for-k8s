#!/bin/bash
set -xeu

source cf-for-k8s-ci/ci/helpers/gke.sh

cluster_name="$(cat pool-lock/name)"
gcloud_auth "${cluster_name}"

build_dir=${PWD}
export CONFIG
CONFIG=$(mktemp)
original_config="${build_dir}/integration-config/${CONFIG_FILE_PATH}"
cp ${original_config} ${CONFIG}

cd capi-bara-tests

export CF_DIAL_TIMEOUT=11
export CF_PLUGIN_HOME=$HOME

# install log-cache plugin to use `cf tail` for tests
cf install-plugin -r CF-Community "log-cache" -f

./bin/test -keepGoing \
  -randomizeAllSpecs \
  -skipPackage=helpers \
  -slowSpecThreshold=300 \
  --flakeAttempts="${FLAKE_ATTEMPTS}" \
  -nodes="${NODES}" \
  -noisySkippings=false \
  . stack
