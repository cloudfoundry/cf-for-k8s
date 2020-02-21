# Deploy CF for K8s in CI

## Prerequisites

You will need the same set of prerequesites listed in the [Deploy CF for K8s](deploy.md#prerequesites) documentation. The CLIs will need to be available in the image used by your CI system.

## with Docker

1. Deploy CF for K8s

  ```bash
  DNS_DOMAIN=<domain>
  docker run -ti -e DNS_DOMAIN=$DNS_DOMAIN \
    -e KUBECONFIG=/kubeconfig \
    -v $(pwd):/src -v ~/.kube/config:/kubeconfig \
    -v /tmp/values:/values \
    relintdockerhubpushbot/cf-for-k8s-ci \
    /src/bin/install-cf.sh /values
  ```

2. Configure DNS for *.<domain> to point to the ingress IP.

  > **Warning** The following script will do it for google cloud, however it **deletes** all existing A records.

  ```bash
  ./hack/update-gcp-dns.sh $DNS_DOMAIN <dns-zone-name>
  ```

3. Run smoke tests

  ```bash
  SMOKE_TEST_PASSWORD=$(cat /tmp/values/cf-install-values.yml | grep admin_password | cut -d " " -f 2 | sed 's/"//g')
  docker run -ti -v $(pwd):/src \
    -e SMOKE_TEST_API_ENDPOINT="https://api.${DNS_DOMAIN}" \
    -e SMOKE_TEST_APPS_DOMAIN="${DNS_DOMAIN}" \
    -e SMOKE_TEST_USERNAME=admin \
    -e SMOKE_TEST_PASSWORD="$SMOKE_TEST_PASSWORD" \
    relintdockerhubpushbot/cf-test-runner \
    /src/hack/run-smoke-tests.sh

4. Cleanup

  ```bash
  docker run -ti -e DNS_DOMAIN=$DNS_DOMAIN \
    -e KAPP_KUBECONFIG=/kubeconfig \
    -v $(pwd):/src -v ~/.kube/config:/kubeconfig \
    relintdockerhubpushbot/cf-for-k8s-ci \
    kapp delete -y -a cf
  ```
## without Docker

The following scripts are designed to be executable in a CI system, as well as locally:

- Generate all required configuration settings for a given domain:

  ```bash
  $ ./hack/generate-values.sh <domain> > <path-to-cf-install-values-yaml>
  $ ./hack/generate-certs.sh <domain> > <path-to-cf-install-certs-yml>
  ```

- Install CF for K8s to your target K8s cluster.

  ```bash
  $ ytt -f ./cf-for-k8s-pr/config \
                -f cf-install-values.yml \
                -f cf-install-certs.yml > \
                cf-install-manifests.yml
  $ kapp deploy -a cf -y -f cf-install-manifests.yml
  ```

- Update the wildcard entry for the given domain with the correct load-balancer IP address (if you are using Google Cloud DNS).

  > **Warning** This script deletes all existing A records.

   ```bash
  $ ./hack/update-gcp-dns.sh <domain> <dns-zone-name>
   ```

- Run the smoke test suite against your CF for K8s installation.

   ```bash
   $ export SMOKE_TEST_API_ENDPOINT=api.<domain>
   $ export SMOKE_TEST_APPS_DOMAIN=<domain>
   $ export SMOKE_TEST_USERNAME=<cf-admin-user>
   $ export SMOKE_TEST_PASSWORD=<cf-admin-password>
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
