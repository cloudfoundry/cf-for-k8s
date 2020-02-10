# Deploying CF for K8s

## Prerequisites

You need the following CLIs on your system to be able to run the script:

* [`bosh`](https://bosh.io/docs/cli-v2-install/#install) - to generate CF Installation Values
* [`kapp`](https://k14s.io/#install)
* [`ytt`](https://k14s.io/#install)

In addition, you will also probably want [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/) for your own debugging and inspection of the system.

Make sure that your Kubernetes config (e.g, `~/.kube/config`) is pointing to the cluster you intend to deploy CF for K8s to. This cluster should be on an IaaS that supports load balancer services (e.g., GKE, AKS, etc.).

## Steps to deploy

1. Clone and initialize this git repository:
   ```bash
   $ git clone https://github.com/cloudfoundry/cf-for-k8s.git
   $ cd cf-for-k8s
   ```

1. Create a "CF Installation Values" file and configure it:
   1. Use `./hack/generate-values.sh <system_domain>` to automatically generate values with [bosh interpolate](https://bosh.io/docs/cli-v2-install/#install)
   ```bash
   $ ./hack/generate-values.sh cf.example.com > /tmp/cf-values.yml
   ```
   1. Alternatively, create a file called `/tmp/cf-values.yml`. You can use `sample-cf-install-values.yml` in this directory as a starting point.
   1. Change the `system_domain` and `app_domain` to your desired domain address
   1. Generate certificates for the above domains and paste them in `crt`, `key`, `ca` values

1. Run the install script with your "CF Install Values" file
   ```bash
   $ ./bin/install-cf.sh /tmp/cf-values.yml
   ```

1. Configure DNS on your IaaS provider to point the wildcard subdomain of your
   system domain and the wildcard subdomain of all apps domains to point to external IP
   of the Istio Ingress Gateway service. You can retrieve the external IP of this service by running
   `kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[*].ip}'`
   1. If you used the `./hack/generate-values.sh` script then you should only
      configure a single DNS record for the domain you passed as input to the
      script and have it resolve to the Ingress Gateway's external IP

## Validate the deployment

1. Set up cf cli to point to CF:
   ```bash
   $ cf api --skip-ssl-validation https://api.<system_domain>
   $ cf auth admin <cf_admin_password>
   ```

1. Enable docker feature:
   ```bash
   $ cf enable-feature-flag diego_docker
   ```

1. Deploy an app:
   ```bash
   $ cf push diego-docker-app -o cloudfoundry/diego-docker-app
   ```
