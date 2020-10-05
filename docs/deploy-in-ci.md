# Deploy CF for K8s in CI

## Prerequisites

You will need the same set of prerequisites listed in the [Deploy CF for K8s](deploy.md#prerequisites) documentation. The CLIs will need to be available in the image used by your CI system.

## Available Scripts/Helpers

The following scripts are designed to be executable in a CI system, as well as locally:

- Generate all external configuration settings for a given domain:

  ```console
  source cf-for-k8s-ci/ci/helpers/generate-values.sh
  generate_values > cf-install-values.yml
  ```

- Generate all internal configuration settings for a given domain:

  ```console
  ./hack/generate-internal-values.sh --values-file cf-install-values.yml > cf-internal-values.yml
  ```

- Install CF for K8s to your target K8s cluster:

  ```console
  ytt -f config -f cf-install-values.yml -f cf-internal-values.yml > cf-for-k8s-rendered.yml
  kapp deploy -a cf -f cf-for-k8s-rendered.yml -y
  ```

- Run the smoke test suite against your CF for K8s installation:

   ```console
   export SMOKE_TEST_API_ENDPOINT=api.<domain>
   export SMOKE_TEST_APPS_DOMAIN=<domain>
   export SMOKE_TEST_USERNAME=<cf-admin-user>
   export SMOKE_TEST_PASSWORD=<cf-admin-password>
   export SMOKE_TEST_SKIP_SSL=true
   ./hack/run-smoke-tests.sh
   ```

## Available Docker Images

There are two Docker images maintained by us that can be used for a CI pipeline:

| Image Tag | Description |
|---|----|
| `relintdockerhubpushbot/cf-for-k8s-ci` | This image contains everything required to generate your installation values and install CF for K8s to a K8s cluster. |
| `relintdockerhubpushbot/cf-test-runner` | This image contains everything required to run the smoke tests. |

## Concourse Example

You can see an example of how we combined these scripts in our own CI pipeline [here](../ci/pipelines/cf-for-k8s.yml).
