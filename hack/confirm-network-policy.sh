#!/usr/bin/env bash

# This is a hack! see https://github.com/cloudfoundry/cf-for-k8s/blob/develop/hack/README.md

echo "WARNING: The hack scripts are intended for development of cf-for-k8s. 
They are not officially supported product bits.  Their interface and behavior
may change at any time without notice." 1>&2

cluster=$1
zone=$2

if [[ "$(gcloud container clusters describe ${cluster} --zone ${zone} |
    ytt -f - -o json | jq .networkPolicy.enabled)" == "true" ]]; then
    echo "Confirmed that node network policy is enabled"
else
    echo "ERROR: node network policy is NOT enabled"
    exit 1
fi
