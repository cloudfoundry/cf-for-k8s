#!/bin/bash -eu

echo ${GCP_SERVICE_ACCOUNT_JSON} > gcp-service-account.json
gcloud auth activate-service-account --key-file=gcp-service-account.json --project=${GCP_PROJECT_NAME} >/dev/null 2>&1

echo "Deleting images in GCR repo ${GCR_REPO_NAME}..."

images=$(gcloud container images list --repository ${GCR_REPO_NAME} --format='get(name)')

set +e
for image in $images; do
  digests=$(gcloud container images list-tags "$image" --format='get(digest)')
  if [[ $? != 0 ]]; then
    echo "Failed to list-tags for $image"
    continue
  fi

  for digest in $digests; do
    full_image="${image}@${digest}"
    gcloud container images delete "$full_image" --force-delete-tags -q >/dev/null 2>&1
    if [[ $? != 0 ]]; then
      echo "Failed to delete $full_image"
    fi
  done
done
set -e

echo "Done deleting all the images"
