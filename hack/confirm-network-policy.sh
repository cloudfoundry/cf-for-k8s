#!/usr/bin/env bash

cluster=$1
zone=$2

if [[ "$(gcloud container clusters describe ${cluster} --zone ${zone} | \
    ytt -f - -o json | jq .networkPolicy.enabled)" == "true" ]]; then
    echo "Confirmed that node network policy is enabled"
else
    echo "ERROR: node network policy is NOT enabled"
    exit 1
fi
