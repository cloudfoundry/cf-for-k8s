#!/bin/bash -eu

BUCKET_PACKAGES="$(jq -r '.bucket_packages' terraform-s3/metadata)"
BUCKET_DROPLETS="$(jq -r '.bucket_droplets' terraform-s3/metadata)"
BUCKET_RESOURCES="$(jq -r '.bucket_resources' terraform-s3/metadata)"
BUCKET_BUILDPACKS="$(jq -r '.bucket_buildpacks' terraform-s3/metadata)"

echo "Generating blobstore values ..."

cat > blobstore-metadata/blobstore-values.yaml <<EOT
#@data/values
---
blobstore:
  endpoint: https://s3.$AWS_REGION.amazonaws.com/
  region: $AWS_REGION
  access_key_id: $AWS_ACCESS_KEY_ID
  secret_access_key: $AWS_SECRET_ACCESS_KEY
  package_directory_key: $BUCKET_PACKAGES
  droplet_directory_key: $BUCKET_DROPLETS
  resource_directory_key: $BUCKET_RESOURCES
  buildpack_directory_key: $BUCKET_BUILDPACKS
  aws_signature_version: "4"
EOT


echo "Finished blobstore installation."
