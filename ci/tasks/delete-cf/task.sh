#!/bin/bash -eu

source cf-for-k8s-ci/ci/helpers/gke.sh

cluster_name="$(cat pool-lock/name)"
gcloud_auth "${cluster_name}"

kapp delete -a cf --yes
