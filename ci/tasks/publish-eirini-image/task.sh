#!/bin/bash -eu

trap "pkill dockerd" EXIT

start-docker &
echo 'until docker info; do sleep 5; done' >/usr/local/bin/wait_for_docker
chmod +x /usr/local/bin/wait_for_docker
timeout 300 wait_for_docker

docker login -u "${DOCKER_USERNAME}" -p "${DOCKER_PASSWORD}"
set -x
docker load -i deplab-image/image.tar
image_id=$(docker images --format '{{.ID}}' | head -n 1)
tag=$(cat eirini-release/version)
docker tag "${image_id}" "${REPOSITORY}":"${tag}"
docker push "${REPOSITORY}":"${tag}"

