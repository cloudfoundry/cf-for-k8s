# cf-k8s-networking-images

## Purpose
This pipeline builds and tests the `routecontroller`, a controller responsible for the reconciliation of cf Routes in cf-for-k8s. Once built the image is pushed to a repository in the cloudfoundry Dockerhub organization.

Once the new image is available it is validated against cf-for-k8s and subsequently bumped on the cf-k8s-networking release-candidate branch. This triggers a CI pipeline of the cf-for-k8s repo itself, which integrates the new release.

## Test Environment
The pipeline uses a gke cluster from the cf-for-k8s cluster pool. See the k8s-pool-management pipeline and the terraform templates in `cf-for-k8s-deploy/gke` for more information on those environments.

## Validation
To validate routecontroller, we run [cf-for-k8s smoke-tests](https://github.com/cloudfoundry/cf-for-k8s/tree/develop/tests/smoke), [a subset of cf-acceptance-tests](https://github.com/cloudfoundry/cf-for-k8s/blob/develop/ci/tasks/run-cats/task.sh), and [cf-k8s-networking-acceptance-tests](https://github.com/cloudfoundry/cf-k8s-networking/tree/develop/test/acceptance).
