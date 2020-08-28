#!/bin/bash -eu

source cf-for-k8s-ci/ci/helpers/gke.sh

if [[ -d pool-lock ]]; then
  if [[ -d tf-vars ]]; then
    echo "You may not specify both pool-lock and tf-vars"
    exit 1
  fi
  cluster_name="$(cat pool-lock/name)"
elif [[ -d tf-vars ]]; then
  if [[ -d terraform ]]; then
    cluster_name="$(cat tf-vars/env-name.txt)"
  else
    echo "You must provide both tf-vars and terraform inputs together"
    exit 1
  fi
else
  echo "You must provide either pool-lock or tf-vars"
  exit 1
fi

gcloud_auth "${cluster_name}"

ACCESS_KEY="$(openssl rand -hex 16)"
SECRET_ACCESS_KEY="$(openssl rand -hex 32)"
SUFFIX="$(openssl rand -hex 16)"
BUCKET_CC_PACKAGES="cc-packages-$SUFFIX"
BUCKET_CC_DROPLETS="cc-droplets-$SUFFIX"
BUCKET_CC_RESOURCES="cc-resources-$SUFFIX"
BUCKET_CC_BUILDPACKS="cc-buildpacks-$SUFFIX"
SIGNATURE_VERSION="4"

NAMESPACE="external-blobstore"
DEPLOYMENT="minio"

kubectl create namespace $NAMESPACE
helm repo add minio https://helm.min.io/
helm install --wait --namespace $NAMESPACE \
            --set accessKey=$ACCESS_KEY,secretKey=$SECRET_ACCESS_KEY \
            --set buckets[0].name=$BUCKET_CC_PACKAGES,buckets[0].policy=none,buckets[0].purge=false \
            --set buckets[1].name=$BUCKET_CC_DROPLETS,buckets[1].policy=none,buckets[1].purge=false \
            --set buckets[2].name=$BUCKET_CC_RESOURCES,buckets[2].policy=none,buckets[2].purge=false \
            --set buckets[3].name=$BUCKET_CC_BUILDPACKS,buckets[3].policy=none,buckets[3].purge=false \
            $DEPLOYMENT minio/minio

cat > blobstore-metadata/blobstore-values.yaml <<EOT
#@data/values
---
blobstore:
  endpoint: http://$DEPLOYMENT.$NAMESPACE.svc.cluster.local:9000
  region: 
  access_key_id: $ACCESS_KEY
  secret_access_key: $SECRET_ACCESS_KEY
  package_directory_key: $BUCKET_CC_PACKAGES
  droplet_directory_key: $BUCKET_CC_DROPLETS
  resource_directory_key: $BUCKET_CC_RESOURCES
  buildpack_directory_key: $BUCKET_CC_BUILDPACKS
  aws_signature_version: $SIGNATURE_VERSION
EOT

echo "Finished installation of $DEPLOYMENT in $NAMESPACE"
