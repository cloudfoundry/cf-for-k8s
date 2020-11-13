#!/usr/bin/env bash

set -eu

SUFFIX=$(openssl rand -hex 6)
echo "Using suffix ${SUFFIX}"

echo "ci-s3-buckets-${SUFFIX}" > tf-vars-s3/env-name.txt

cat <<EOT > tf-vars-s3/input.tfvars
region = "${AWS_REGION}"
aws_access_key_id = "${AWS_ACCESS_KEY_ID}"
aws_secret_access_key = "${AWS_SECRET_ACCESS_KEY}"
bucket_suffix = "${SUFFIX}"
EOT
