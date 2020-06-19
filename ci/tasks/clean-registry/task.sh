#!/bin/bash -eu

echo ${GCP_SERVICE_ACCOUNT_JSON} > gcp-service-account.json
gcloud auth activate-service-account --key-file=gcp-service-account.json --project=${GCP_PROJECT_NAME} >/dev/null 2>&1

IMAGES=$(gcloud container images list --repository ${GCR_REPO_NAME} | grep -v NAME)

echo "Deleting images in GCR repo ${GCR_REPO_NAME}..."

for image in $IMAGES; do
  gcloud container images delete $image --force-delete-tags -q >/dev/null 2>&1
done

echo "Done deleting all the images"
