# Deploy CF for K8s in CI

## Prerequisites

You will need the same set of prerequisites listed in the [Deploy CF for K8s](deploy.md#prerequisites) documentation. The CLIs will need to be available in the image used by your CI system.

## Available Scripts

The following scripts are designed to be executable in a CI system, as well as locally:

- Generate all required configuration settings for a given domain:

  ```bash
  $ ./hack/generate-values.sh --cf-domain <cf-domain> --gcr-service-account-json <path-to-kpack-gcr-service-account-json> > cf-install-values.yml
  ```

- Install CF for K8s to your target K8s cluster.

  ```bash
  $ ./bin/install-cf.sh <path-to-cf-install-values-yaml>
  ```

- Update the wildcard entry for the given domain with the correct load-balancer IP address (if you are using Google Cloud DNS).

   ```bash
  $ ./hack/update-gcp-dns.sh <cf-domain> <dns-zone-name>
   ```

- Run the smoke test suite against your CF for K8s installation.

   ```bash
   $ export SMOKE_TEST_API_ENDPOINT=api.<domain>
   $ export SMOKE_TEST_APPS_DOMAIN=<domain>
   $ export SMOKE_TEST_USERNAME=<cf-admin-user>
   $ export SMOKE_TEST_PASSWORD=<cf-admin-password>
   $ export SMOKE_TEST_SKIP_SSL=true
   $ ./hack/run-smoke-tests.sh
   ```

## Available Docker Images

There are two Docker images maintained by us that can be used for a CI pipeline:

| Image Tag | Description |
|---|----|
| `relintdockerhubpushbot/cf-for-k8s-ci` | This image contains everything required to generate your installation values and install CF for K8s to a K8s cluster. |
| `relintdockerhubpushbot/cf-test-runner` | This image contains everything required to run the smoke tests. |

## Concourse Example

You can see an example of how we combined these scripts in our own CI pipeline [here](../ci/pipelines/cf-for-k8s.yml).
