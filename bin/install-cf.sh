#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage $(basename "$0") <path-containing-values-yaml>"
  exit 1
fi

# attempt to guess at kubeconfig location
export KAPP_KUBECONFIG=${KUBECONFIG:-"~/.kube/config"}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../config"

VALUES_DIR="$1"

mkdir -p "${VALUES_DIR}"

if [[ -e "${VALUES_DIR}/cf-install-values.yml" ]]; then
  DNS_DOMAIN=$(grep "system_domain" "${VALUES_DIR}/cf-install-values.yml" | cut -d " " -f 2)
fi

if [[ "${DNS_DOMAIN}" == "" ]]; then
  echo "Please set the DNS_DOMAIN environment variable"
  exit 1
fi

# Create values files if they don't exist
echo "==> Checking values files"
if [[ ! -e "${VALUES_DIR}/cf-install-values.yml" ]]; then
  echo "----> Generating values file"
  "${SCRIPT_DIR}/../hack/generate-values.sh" "${DNS_DOMAIN}" > \
   "${VALUES_DIR}/cf-install-values.yml"
fi

if [[ ! -e "${VALUES_DIR}/cf-install-certs.yml" ]]; then
  echo "----> Generating certificates file"
  "${SCRIPT_DIR}/../hack/generate-certs.sh" "${DNS_DOMAIN}" > \
    "${VALUES_DIR}/cf-install-certs.yml"
fi

# Deploy CF for Kubernetes
echo "==> Deploy CF for Kubernetes"
echo "----> Create Deployment Manifests"
ytt -f "${CONFIG_DIR}" \
  -f "${VALUES_DIR}/cf-install-values.yml" \
  -f "${VALUES_DIR}/cf-install-certs.yml" > \
  "${VALUES_DIR}/cf-install-manifests.yml"

echo "----> Deploy Manifest"
kapp deploy -a cf -y -f "${VALUES_DIR}/cf-install-manifests.yml"

echo "----> Deployment Complete"
if kubectl cluster-info 2>/dev/null >/dev/null; then
  echo Ingress IP: "$(kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[*].ip}')"
  echo Ingress DNS: "${DNS_DOMAIN}"
fi