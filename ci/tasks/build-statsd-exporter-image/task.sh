#!/bin/bash
set -euo pipefail

trap "pkill dockerd" EXIT

start-docker &
echo 'until docker info; do sleep 5; done' >/usr/local/bin/wait_for_docker
chmod +x /usr/local/bin/wait_for_docker
timeout 300 wait_for_docker

<<<"$DOCKERHUB_PASSWORD" docker login --username "$DOCKERHUB_USERNAME" --password-stdin

pushd cf-for-k8s-images/images/build/statsd-exporter > /dev/null
./build.sh
popd > /dev/null

# image_ref="$(yq -r '.overrides[] | select(.image | test("/statsd_exporter-cf-for-k8s")).newImage' images/build/statsd-exporter/kbld.lock.yml)"
# sed -i'' -e "s| metric_proxy:.*| metric_proxy: \"$image_ref\"|" metric-proxy/config/values/images.yml
