# cf-for-k8s-dev-tooling

## Purpose
### Long-lived SLI Cluster
Deploys the GKE cluster used in `cf-for-k8s-stability-tests` pipeline

### Docker Images
Builds docker images used by CI:
  - `cf-for-k8s-ci` - used throughout Concourse pipelines
  - `cf-for-k8s-aws` - has AWS CLI and IAM authenticator
  - `cf-for-k8s-dind` - for situations where we need to run Docker inside Docker (i.e. dind)
  - `cf-for-k8s-azure` - has Azure CLI
  - `cf-for-k8s-deplab` - has deplab installed
  - `cf-for-k8s-gh-pages` - has hugo for building docs
  - `cf-k8s-networking-integration` - has tools for running network integration tests, including ginkgo, kubectl, k9s, etc. Stored under the `cf-k8s-networking-integration` tag of the `cf-for-k8s-dind` image

### RDS Databases
Creates and destroys the rds database used by the validate-rds job in the cf-for-k8s-main pipeline.
