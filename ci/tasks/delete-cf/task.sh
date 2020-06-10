#!/bin/bash -eu

source cf-for-k8s-ci/ci/helpers/gke.sh

gcloud_auth "pool-lock/name"

kapp delete -a cf --yes
