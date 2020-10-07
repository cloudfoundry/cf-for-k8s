#!/bin/bash
set -euo pipefail

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

CF_VARS=$(cat blobstore-metadata/blobstore-values.yaml)

ENDPOINT=$(yq -r '.blobstore.endpoint' <<< "$CF_VARS")
ACCESS_KEY=$(yq -r '.blobstore.access_key_id' <<< "$CF_VARS")
SECRET_ACCESS_KEY=$(yq -r '.blobstore.secret_access_key' <<< "$CF_VARS")
BUCKET=$(yq -r '.blobstore.resource_directory_key' <<< "$CF_VARS")
SUFFIX=$(openssl rand -hex 12)

IMAGE="minio/mc"

APP_NAME="blobstore-test"
DNS_DOMAIN=$(cat env-metadata/dns-domain.txt)

cf api api.${DNS_DOMAIN} --skip-ssl-validation
cf auth admin "$(cat env-metadata/cf-admin-password.txt)"
cf create-org org
cf target -o org
cf create-space space
cf target -o org -s space

echo "Pushing ${APP_NAME}"
cf push ${APP_NAME} -p cf-for-k8s/tests/smoke/assets/test-node-app
echo "Verify availability of ${APP_NAME}"
curl -k https://${APP_NAME}.apps.${DNS_DOMAIN}
echo "Confirmed that app is available"

if [ ${EXTERNAL_BLOBSTORE} == "incluster" ];then
  HOSTNAME=$(echo $ENDPOINT | cut -d'/' -f3)
  ENV="MC_HOST_minio=http://$ACCESS_KEY:$SECRET_ACCESS_KEY@$HOSTNAME"

  CC_PACKAGES_KEY=$(kubectl --namespace=cf-system run "minio-client-$SUFFIX" -i --quiet --rm --labels "release=cf-blobstore,app.kubernetes.io/name=cf-api-server" --restart=Never --image=$IMAGE --env=$ENV --overrides='{"apiVersion":"v1","metadata":{"annotations":{"sidecar.istio.io/inject":"false"}}}' -- ls --recursive --json minio/$BUCKET/ | jq -r '.key')
else
  echo "You need to specifiy EXTERNAL_BLOBSTORE"
  exit 1
fi

echo "Checking if objects exist in bucket $BUCKET on $ENDPOINT"
if [ -z ${CC_PACKAGES_KEY} ];then
    echo "No objects found in $BUCKET"
    exit 1
fi

echo "Check successfully completed."
