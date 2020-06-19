#!/bin/bash -eu

source cf-for-k8s-ci/ci/helpers/gke.sh

set +e
gcloud_auth
set -e

IMAGES=$(gcloud container images list --repository ${GCR_REPO_NAME} | grep -v NAME)

echo "Deleting images in GCR repo ${GCR_REPO_NAME}..."

for image in $IMAGES; do
  gcloud container images delete $image --force-delete-tags -q >/dev/null 2>&1
done

echo "Done deleting all the images"
