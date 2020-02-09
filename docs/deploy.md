# Deploying CF for K8s

## Prerequisites

You need the following CLIs on your system to be able to run the script:

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
   $ ./hack/generate-values.sh <system_domain> > /tmp/cf-values.yml
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
      configure a single DNS record for the wildcard subdomain of the domain
      you passed as input to the script and have it resolve to the Ingress
      Gateway's external IP

## Validate the deployment

1. Get the `<cf_admin_password>` with the `bosh interpolate /tmp/cf-values.yml --path /cf_admin_password`
command and set up cf CLI to point to CF:
   ```bash
   $ cf api --skip-ssl-validation https://api.<system_domain>
   $ cf auth admin <cf_admin_password>
   ```

1. Enable docker feature:
   ```bash
   $ cf enable-feature-flag diego_docker
   ```

1. Create an org and space, and target them:
   ```bash
   $ cf create-org test-org
   $ cf create-space -o test-org test-space
   $ cf target -o test-org -s test-space
   ```

1. Deploy an app:
   ```bash
   $ cf push diego-docker-app -o cloudfoundry/diego-docker-app
   ```

1. Confirm the app is running and reachable:
   ```bash
   $ curl -s http://diego-docker-app.<system_domain>/env | ytt -f-
   BAD_QUOTE: ''''
   BAD_SHELL: $1
   CF_INSTANCE_ADDR: 0.0.0.0:8080
   CF_INSTANCE_INTERNAL_IP: 10.32.2.15
   CF_INSTANCE_IP: 10.32.2.15
   CF_INSTANCE_PORT: "8080"
   CF_INSTANCE_PORTS: '[{"external":8080,"internal":8080}]'
   HOME: /home/some_docker_user
   HOSTNAME: diego-docker-app-test-space-2a80ac86bf-0
   KUBERNETES_PORT: tcp://10.0.16.1:443
   ...
   VCAP_APP_HOST: 0.0.0.0
   VCAP_APP_PORT: "8080"
   VCAP_SERVICES: '{}'
   ```

## Delete the deployment

1. Uninstall CF
   ```
   $ kapp delete -a cf -y
   ```
