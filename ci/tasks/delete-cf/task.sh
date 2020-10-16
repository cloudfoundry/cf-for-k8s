#!/bin/bash -eu

source cf-for-k8s-ci/ci/helpers/gke.sh

if [[ -d pool-lock ]]; then
  if [[ -d tf-vars ]]; then
    echo "You may not specify both pool-lock and tf-vars"
    exit 1
  fi
  cluster_name="$(cat pool-lock/name)"
  load_balancer_static_ip="$(jq -r '.lb_static_ip' pool-lock/metadata)"
elif [[ -d tf-vars ]]; then
  if [[ -d terraform ]]; then
    cluster_name="$(cat tf-vars/env-name.txt)"
    load_balancer_static_ip="$(jq -r '.lb_static_ip' terraform/metadata)"
  else
    echo "You must provide both tf-vars and terraform inputs together"
    exit 1
  fi
else
  echo "You must provide either pool-lock or tf-vars"
  exit 1
fi

gcloud_auth "${cluster_name}"

kapp delete -a cf --yes
