#!/usr/bin/env bash

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: $(basename "$0") <dns-domain> <dns-zone-name>"
  exit 1
fi

# Ensure that required executables exist
gcloud --version > /dev/null 2>&1 || (echo "Missing required \"gcloud\" executable." && exit 1)
kubectl version --client=true > /dev/null 2>&1 || (echo "Missing required \"kubectl\" executable." && exit 1)

DNS_DOMAIN="$1"
DNS_ZONE_NAME="$2"

echo "Discovering Istio Gateway LB IP..."
external_static_ip=$(kubectl get services/istio-ingressgateway -n istio-system --output="jsonpath={.status.loadBalancer.ingress[0].ip}")

echo "Starting transaction..."
gcloud dns record-sets transaction start --zone="${DNS_ZONE_NAME}"

echo "Deleting existing DNS A records..."
gcloud dns record-sets list --zone="${DNS_ZONE_NAME}" --format=json | \
  jq -r '.[] | select(.type == "A") | ("\"" + .name + "\" \"" + (.rrdatas | join(" ")) + "\"")' | \
  xargs -n2 -I{} -t sh -c "gcloud dns record-sets transaction remove --ttl=5 --type=A --zone=\"${DNS_ZONE_NAME}\" --name={} --verbosity=debug"

echo "Configuring DNS for external IP \"${external_static_ip}\"..."
gcloud dns record-sets transaction add --name "*.${DNS_DOMAIN}" --type=A --zone="${DNS_ZONE_NAME}" --ttl=5 "${external_static_ip}" --verbosity=debug

echo "Executing transaction..."
gcloud dns record-sets transaction execute --zone="${DNS_ZONE_NAME}" --verbosity=debug

resolved_ip=''
while [ "$resolved_ip" != "$external_static_ip" ]; do
  echo "Waiting for DNS to propagate..."
  sleep 5
  resolved_ip=$(nslookup "*.$DNS_DOMAIN" | grep Address | grep -v ':53' | cut -d ' ' -f2)
done
