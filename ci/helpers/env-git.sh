#!/bin/bash

commit-long-lived-sli-cf-vars() {

    cp -r relint-envs/. relint-envs-updated
    mkdir -p relint-envs-updated/k8s-environments/long-lived-sli
    cf_vars_rel_path="k8s-environments/long-lived-sli/cf-vars.yaml"
    cf_values_rel_path="k8s-environments/long-lived-sli/cf-values.yaml"
    cp "/tmp/${DNS_DOMAIN}/cf-vars.yaml" relint-envs-updated/${cf_vars_rel_path}
    cp "cf-install-values.yml" relint-envs-updated/${cf_values_rel_path}

    pushd relint-envs-updated > /dev/null
        set +e
        git diff --exit-code ${cf_values_rel_path} ${cf_vars_rel_path} > /dev/null
        error_code=$?
        set -e

        if [[ ${error_code} != 0 ]]; then
            echo "Committing changes to relint-envs long-lived sli values & vars"
            git config user.email "cf-release-integration@pivotal.io"
            git config user.name "relint-ci"
            git add .
            git commit -m "Update long-lived environment"
        fi

    popd > /dev/null
}
