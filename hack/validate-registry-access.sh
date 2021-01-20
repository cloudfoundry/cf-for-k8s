#!/usr/bin/env bash
echo "WARNING: The hack scripts are intended for development of cf-for-k8s.
They are not officially supported product bits. Their interface and behavior" \
"may change at any time without notice." 1>&2

# This is a hack! see https://github.com/cloudfoundry/cf-for-k8s/blob/develop/hack/README.md
set -eo pipefail

# requirements
# General: docker cli, python yq
# GCR: run `gcloud auth configure-docker`
#      gcloud must be in the path

show_help() {
    echo ""
    echo "Confirm that app_registry credentials have push access to the specified repository."
    echo ""
    echo "usage:"
    echo "  validate-registry-access.sh <yaml with app_registry configuration>"
    echo ""
    exit 1
}

docker_tag_and_push() {
    echo "building tiny test docker image..."
    docker build --tag ${docker_tag} $(dirname $0)/app-registry-check-dockerfile/ 1>/dev/null

    echo "docker push-ing ${docker_tag} to test push access..."
    docker push ${docker_tag} 1>/dev/null

    docker rmi ${docker_tag} 1>/dev/null
    echo "Confirmed push access to $1"
}

main() {

    values_file="$1"

    if [[ -z ${values_file} || ${values_file} = "-h" || ${values_file} = "--help" ]]; then
        show_help
    fi

    if [[ "$(yq -r .app_registry $values_file)" == "null" ]]; then
        echo "No app_registry key found at top level of ${values_file}"
        exit 1
    fi

    registry_host="$(yq -r .app_registry.hostname ${values_file})"
    username="$(yq -r .app_registry.username ${values_file})"
    repo="$(yq -r .app_registry.repository_prefix ${values_file})"
    docker_tag="${repo}/cfk8s-test-delete-me"

    if [[ $registry_host = "https://index.docker.io/v1/" ]]; then
        password="$(yq -r .app_registry.password ${values_file})"

        echo "logging into dockerhub with username and password"
        docker login -u "${username}" -p "${password}"

        docker_tag_and_push "dockerhub registry"

    elif [[ $registry_host = "gcr.io" ]]; then

        tmp_file="./.abc123delete.me"
        trap "rm ${tmp_file}" EXIT

        yq -r .app_registry.password ${values_file} > ${tmp_file}
        gcr_email="$(yq -r .app_registry.password ${values_file} | jq -r .client_email)"
        project="$(yq -r .app_registry.password ${values_file} | jq -r .project_id)"

        echo "gcloud auth-ing with service account..."
        gcloud auth activate-service-account ${gcr_email} --key-file=${tmp_file} --project=${project} 1>/dev/null

        docker_tag_and_push "gcr"

    else
        echo "expected host to be gcr.io or https://index.docker.io/v1/. I'm not yet smart enough to validate azurecr.io"
        exit 1
    fi
}

main "$@"
