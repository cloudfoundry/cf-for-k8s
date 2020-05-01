#!/usr/bin/env bash
# 
# Update the app domain in Google Cloud DNS with the correct LB IP 
# This is a hack! 
# Please see https://github.com/cloudfoundry/cf-for-k8s/blob/develop/hack/README.md

set -eu

echo "WARNING: The hack scripts are intended for development of cf-for-k8s. 
They are not officially supported product bits.  Their interface and behavior
may change at any time without notice." 1>&2

if [ $# -lt 2 ]; then
  echo "Usage: $(basename "$0") <dns-domain> <dns-zone-name>"
  exit 1
fi

# Globals
DNS_DOMAIN="$1"
DNS_ZONE_NAME="$2"

function dep_check() {

  REQS=(gcloud kubectl)
  MISSING=()

  for DEP in ${REQS[@]}; do
    command -v $DEP >/dev/null 2>&1 || { MISSING+=($DEP); }
  done

  if [ ${#MISSING[@]} -ne 0 ]; then
    printf 'Missing %s: Please install.\n' "${MISSING[@]}"
    exit 1;
  fi
}

function get_gw_address() {

  local LB_IP=$(kubectl get services/istio-ingressgateway -n istio-system --output="jsonpath={.status.loadBalancer.ingress[0].ip}")
  if [ -z ${LB_IP} ]; then
    echo "Gateway LB IP not found. Exiting."
    exit 127
  fi
  echo ${LB_IP}
}

function get_existing_record() {

  HOST_RECORD_JSON="$( gcloud dns record-sets list --zone="${DNS_ZONE_NAME}" --name "*.${DNS_DOMAIN}" --format=json | jq .[] )"
  if [ ! -z "${HOST_RECORD_JSON}" ]; then
    HOST_RECORD=$(echo ${HOST_RECORD_JSON} | jq -r '.rrdatas[]')
    TTL=$(echo ${HOST_RECORD_JSON} | jq -r '.ttl')
    echo ${HOST_RECORD} ${TTL}
  else
    echo ""
  fi
}

dep_check
LB_IP=$(get_gw_address) # from kubectl
read HOST_RECORD TTL < <(get_existing_record) # from DNS

if [[ "${LB_IP}" == "${HOST_RECORD}" ]]; then
  echo "*.${DNS_DOMAIN} -> ${LB_IP}. No update needed."
  exit 0
else
  gcloud dns record-sets transaction start --zone="${DNS_ZONE_NAME}"
  if [ ! -z "${HOST_RECORD}" ]; then 
    gcloud dns record-sets transaction remove --name "*.${DNS_DOMAIN}" --type=A --zone="${DNS_ZONE_NAME}" --ttl=${TTL} "${HOST_RECORD}" --verbosity=debug
  fi
  gcloud dns record-sets transaction add --name "*.${DNS_DOMAIN}" --type=A --zone="${DNS_ZONE_NAME}" --ttl=5 "${LB_IP}" --verbosity=debug 
  gcloud dns record-sets transaction execute --zone="${DNS_ZONE_NAME}" --verbosity=debug 

  SUCCESS_COUNT=0
  while [[ ${SUCCESS_COUNT} < 3 ]]; do
    DNS_QUERY=$(nslookup *.${DNS_DOMAIN} | awk '/^Address: / { print $2 }')
    if [[ "${LB_IP}" == "${DNS_QUERY}" ]]; then
      SUCCESS_COUNT=$((SUCCESS_COUNT+1))
    fi
    sleep 5
  done
  echo "*.${DNS_DOMAIN} -> ${LB_IP} successfully updated. Exiting."
  exit 0
fi
