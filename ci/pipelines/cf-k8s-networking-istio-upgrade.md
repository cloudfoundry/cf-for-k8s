# cf-k8s-networking-istio-upgrade

## Purpose
This pipeline is designed to test istio upgrades as new patch releases become available within a specified minor version line. Upon validation, the release update is pushed to the `istio-version-bump` branch on `cf-for-k8s`.

## Updating
To update the minor version line being tested by the pipeline, update the `tag_filter` field of the `istio-release` resource in the pipeline template.

## Test Environment
The pipeline uses a gke cluster from the cf-for-k8s cluster pool. See the k8s-pool-management pipeline and the terraform templates in `cf-for-k8s-deploy/gke` for more information on those environments.

## Validation
To validate the new version, the pipeline deploys the current version of istio as part of a fresh installation of cf-for-k8s. It then bumps the istio version using uptimer to measure availability of an app and the cf api server during the upgrade. Subsequently, we run the cf-k8s-networking acceptance tests to validate the behavior of networking once the upgrade is complete.

## Disclaimer
This pipeline is not currently committing back to cf-for-k8s, so bumping istio requires a pr be opened manually against the `istio-version-bump` branch or a clone of it. 