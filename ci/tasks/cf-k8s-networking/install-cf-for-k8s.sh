#!/usr/bin/env bash

set -euo pipefail

source cf-for-k8s-ci/ci/tasks/cf-k8s-networking/helpers.sh

# ENV
: "${CLOUDSDK_COMPUTE_REGION:?}"
: "${CLOUDSDK_COMPUTE_ZONE:?}"
: "${GCP_SERVICE_ACCOUNT_KEY:?}"
: "${GCP_PROJECT:?}"
: "${SHARED_DNS_ZONE_NAME:?}"
: "${KAPP_TIMEOUT:?}"
: "${USE_LATEST_NETWORKING:?}"


function install_cf() {
    sleep 5

    if [[ "${USE_LATEST_NETWORKING}" == "true" && -d "./cf-k8s-networking" ]]; then
        echo "Updating cf-for-k8s to use this version of cf-k8s-networking..."
        pushd cf-for-k8s
            vendir sync --directory config/networking/_ytt_lib/cf-k8s-networking=../cf-k8s-networking
        popd
    fi

    export KUBECONFIG=kube-config.yml

    if [ "${REGIONAL_CLUSTER}" = true ]; then
        # unset zone since we are targetting a regional cluster
        unset CLOUDSDK_COMPUTE_ZONE
    fi

    gcloud auth activate-service-account --key-file=<(echo "${GCP_SERVICE_ACCOUNT_KEY}") --project="${GCP_PROJECT}"
    gcloud container clusters get-credentials "${CLUSTER_NAME}"

    if [[ ! -d "./cf-install-values" ]]; then
        echo "Generating install values..."
        echo -n $KPACK_GCR_ACCOUNT_KEY > /tmp/service-account.json
        mkdir -p cf-install-values
        cf-for-k8s/hack/generate-values.sh -d "${CF_DOMAIN}" -g /tmp/service-account.json > cf-install-values/cf-install-values.yml
    fi

    cp cf-install-values/cf-install-values.yml cf-install-values-out/cf-install-values.yml

    echo "Installing CF..."
    if [[ "${USE_NODEPORT_SERVICE}" == "true" ]]; then
        kapp deploy -a cf -f <(ytt -f cf-for-k8s/config -f cf-for-k8s/config-optional/ingressgateway-service-nodeport.yml -f cf-install-values-out/cf-install-values.yml) \
            -y --wait-timeout ${KAPP_TIMEOUT}
    else
        kapp -y deploy -a cf -f <(ytt -f cf-for-k8s/config -f cf-install-values-out/cf-install-values.yml) \
             --wait-timeout ${KAPP_TIMEOUT}
    fi

    bosh interpolate --path /cf_admin_password cf-install-values/cf-install-values.yml > env-metadata/cf-admin-password.txt
    echo "${CF_DOMAIN}" > env-metadata/dns-domain.txt
}

function configure_dns() {
    echo "Discovering Gateway LB IP"
    external_static_ip=""
    while [ -z $external_static_ip ]; do
      sleep 1
      external_static_ip=$(kubectl get services -A -ojson | jq -r '.items[] | select(.spec.type == "LoadBalancer") | .status.loadBalancer.ingress[0].ip')
    done

    echo "Configuring DNS for external IP: ${external_static_ip}"
    gcloud dns record-sets transaction start --zone="${SHARED_DNS_ZONE_NAME}"
    gcp_records_json="$( gcloud dns record-sets list --zone "${SHARED_DNS_ZONE_NAME}" --name "*.${CF_DOMAIN}" --format=json )"
    record_count="$( echo "${gcp_records_json}" | jq 'length' )"
    if [ "${record_count}" != "0" ]; then
        existing_record_ip="$( echo "${gcp_records_json}" | jq -r '.[0].rrdatas | join(" ")' )"
        gcloud dns record-sets transaction remove --name "*.${CF_DOMAIN}" --type=A --zone="${SHARED_DNS_ZONE_NAME}" --ttl=300 "${existing_record_ip}" --verbosity=debug
    fi
    gcloud dns record-sets transaction add --name "*.${CF_DOMAIN}" --type=A --zone="${SHARED_DNS_ZONE_NAME}" --ttl=300 "${external_static_ip}" --verbosity=debug

    echo "Contents of transaction.yaml:"
    cat transaction.yaml
    gcloud dns record-sets transaction execute --zone="${SHARED_DNS_ZONE_NAME}" --verbosity=debug

    resolved_ip=''
    # disable pipefail while DNS propagates ...
    set +o pipefail
    while [ "$resolved_ip" != "$external_static_ip" ]; do
      echo "Waiting for DNS to propagate..."
      sleep 5
      resolved_ip=$(nslookup "*.${CF_DOMAIN}" | grep Address | grep -v ':53' | cut -d ' ' -f2)
    done
    set -o pipefail
    echo  "we made it! 🥖🤓"
}

function eval_with_retry() {
    local command="${1}"
    local tries="${2:-5}"
    local timeout="${3:-2}"

    local i=0

    until [ "${i}" -ge "${tries}" ]
    do
       eval "${command}" && break
       i=$((i+1))
       echo "Failed to run the command, retrying in ${timeout} seconds..."
       sleep "${timeout}"
    done
}

function main() {
    initialize_gke_env_vars
    install_cf
    configure_dns
    eval_with_retry 'cf api https://api.${CF_DOMAIN} --skip-ssl-validation '
}

main
