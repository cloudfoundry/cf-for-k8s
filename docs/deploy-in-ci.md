# Deploy CF for K8s in CI

## Prerequesites

You will need the same set of prerequesites listed in the [Deploy CF for K8s](deploy.md#prerequesites) documentation. The CLIs will need to be available in the image used by your CI system.

## Available Scripts

The following scripts are designed to be runnable in a CI system, as well as locally:

- `./hack/generate-values.sh <domain> > <path-to-cf-install-values-yaml>`
  - Generates all required configuration settings for a given domain
- `./bin/install-cf.sh <path-to-cf-install-values-yaml>`
  - Install CF for K8s to your target K8s cluster.
- `./hack/update-gcp-dns.sh <domain> <dns-zone-name>`
  - Update the wildcard entry for the given domain with the correct load-balancer IP address (if you are using Google Cloud DNS).
- `./hack/run-smoke-tests.sh`
  - Run the smoke test suite against your CF for K8s installation. This requires the following environment variables to be set:
    - `SMOKE_TEST_API_ENDPOINT`
    - `SMOKE_TEST_APPS_DOMAIN`
    - `SMOKE_TEST_USERNAME`
    - `SMOKE_TEST_PASSWORD`
    
## Available Docker Images

There are two Docker images maintained by us that can be used for a CI pipeline:

- `relintdockerhubpushbot/cf-for-k8s-ci`
  - This image contains everything required to generate your installation values and install CF for K8s to a K8s cluster.
- `relintdockerhubpushbot/cf-test-runner`
  - This image contains everything required to run the smoke tests.

## Concourse Example

You can see an example of how we combined these scripts in our own CI pipeline [here](../ci/pipelines/cf-for-k8s.yml).
