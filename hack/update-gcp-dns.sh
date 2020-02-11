#!/usr/bin/env bash

set -eu

if [ $# -lt 2 ]; then
  echo "Usage: $(basename $0) <dns-domain> <dns-zone-name>"
  exit 1
fi

# Ensure that required executables exist
gcloud --version > /dev/null 2>&1 || (echo "Missing required \"gcloud\" executable." && exit 1)
kubectl version --client=true > /dev/null 2>&1 || (echo "Missing required \"kubectl\" executable." && exit 1)

DNS_DOMAIN="$1"
DNS_ZONE_NAME="$2"

echo "Discovering Istio Gateway LB IP..."
external_static_ip=$(kubectl get services/istio-ingressgateway -n istio-system --output="jsonpath={.status.loadBalancer.ingress[0].ip}")

echo "Configuring DNS for external IP \"${external_static_ip}\"..."
gcloud dns record-sets transaction start --zone="${DNS_ZONE_NAME}"
gcp_records_json="$( gcloud dns record-sets list --zone="${DNS_ZONE_NAME}" --name "*.${DNS_DOMAIN}" --format=json )"
record_count="$( echo "${gcp_records_json}" | jq 'length' )"
if [ "${record_count}" != "0" ]; then
  existing_record_ip="$( echo "${gcp_records_json}" | jq -r '.[0].rrdatas | join(" ")' )"
  gcloud dns record-sets transaction remove --name "*.${DNS_DOMAIN}" --type=A --zone="${DNS_ZONE_NAME}" --ttl=5 "${existing_record_ip}" --verbosity=debug
fi
gcloud dns record-sets transaction add --name "*.${DNS_DOMAIN}" --type=A --zone="${DNS_ZONE_NAME}" --ttl=5 "${external_static_ip}" --verbosity=debug
gcloud dns record-sets transaction execute --zone="${DNS_ZONE_NAME}" --verbosity=debug

echo "Waiting for DNS to propagate..."
resolved_ip=''
while [ "$resolved_ip" != "$external_static_ip" ]; do
  sleep 5
  resolved_ip=$(nslookup "*.$DNS_DOMAIN" | grep Address | grep -v ':53' | cut -d ' ' -f2)
  echo "Resolved DNS IP \"$resolved_ip\" != expected LB static IP \"$external_static_ip\""
done
