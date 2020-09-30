# Deploying Cloud Foundry on a Kubernetes cluster

- [Prerequisites](#prerequisites)
  * [Required Tools](#required-tools)
  * [Kubernetes Cluster Requirements](#kubernetes-cluster-requirements)
  * [Container Registry Requirements](#container-registry-requirements)
  * [Setup an OCI-compliant registry](#setup-an-oci-compliant-registry)
- [Steps to deploy](#steps-to-deploy)
- [Validate the deployment](#validate-the-deployment)
- [Delete the cf-for-k8s deployment](#delete-the-cf-for-k8s-deployment)
- [Additional resources](#additional-resources)
- [Roadmap and milestones](#roadmap-and-milestones)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

## Prerequisites

### Required Tools

You need the following CLIs on your system to be able to run the script:

- `ytt` [install link](https://k14s.io/#install) [github repo](https://github.com/k14s/ytt)
  - cf-for-k8s uses `ytt` to create and maintain reusable YAML templates. You can visit the ytt [playground](https://get-ytt.io/) to learn more about its templating features.
- `kapp` [install link](https://k14s.io/#install) [github repo](https://github.com/k14s/kapp)
  - cf-for-k8s uses `kapp` to manage its lifecycle. `kapp` will first show you a list of resources it plans to install on the cluster and then will attempt to install those resources. `kapp` will not exit until all resources are deployed and their status is running. See all options by running `kapp help`.
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [`cf cli`](https://docs.cloudfoundry.org/cf-cli/install-go-cli.html) (v7+)

> Make sure that your Kubernetes config (e.g, `~/.kube/config`) is pointing to the cluster you intend to deploy cf-for-k8s to.

### Kubernetes Cluster Requirements

To deploy cf-for-k8s as is, the cluster should:

- be running Kubernetes version within range 1.16.x to 1.19.x
- have a minimum of 5 nodes
- have a minimum of 4 CPU, 15GB memory per node
- have a CNI plugin (Container Network Interface plugin) that supports network policies (otherwise, the NetworkPolicy resources applied by cf-for-k8s will have no effect)
- support `LoadBalancer` services
- most IaaSes come with `metrics-server`, but if yours does not come with one (for example, if you are using `kind`), you will need to include `add_metrics_server_components: true` in your values file.
- defines a default StorageClass
  - requires [additional config on vSphere](https://vmware.github.io/vsphere-storage-for-kubernetes/documentation/storageclass.html), for example

### Container Registry Requirements

To deploy cf-for-k8s as is, you will need to provide an OCI-compliant registry.

### Setup an OCI-compliant registry

You must provide a container registry.  You can choose any of the cloud provider registries, such as [hub.docker.com](https://hub.docker.com/), [Google container registry](https://cloud.google.com/container-registry) or [Azure container registry](https://azure.microsoft.com/en-us/services/container-registry/).

Currently, we test the following two container registries:

- [hub.docker.com](https://hub.docker.com/) is pretty easy to get started:
   1. Create an account in [hub.docker.com](https://hub.docker.com/). Note down the user name and password you used during signup.
   1. Create a repository in your account. Note down the repository name.

- [Google Container Registry](https://cloud.google.com/container-registry) is convenient if you are already using Google infrastructure:
  1. Create a GCP Service Account with `Storage/Storage Admin` role.
  1. Create a Service Key JSON and download it to the machine from which you will install cf-for-k8s (referred to, below, as `path-to-kpack-gcr-service-account`).

## Steps to deploy

1. Clone and initialize this git repository:

   ```console
   git clone https://github.com/cloudfoundry/cf-for-k8s.git
   cd cf-for-k8s
   VALUES_DIR=<your-values-dir-path> ; mkdir -p ${VALUES_DIR}
   ```

1. Create a "CF Installation Values" file and configure it<a name="cf-values"></a>:

     1. Clone one of the sample values files from the `sample-cf-install-values` directory to use as a starting point.

        ```console
        cp sample-cf-install-values/kind.yml ${VALUES_DIR}/cf-values.yml
        ```

     1. Open the file and change the `system_domain` and `app_domain` to your desired domain address.
     1. Generate certificates for the above domains and paste them in `crt`, `key`, `ca` values
        - **IMPORTANT** Your certificates must include a subject alternative name entry for the internal `*.cf-system.svc.cluster.local` domain in addition to your chosen external domain.
     1. Adjust the other configuration flags as appropriate for your cluster.

1. Provide your credentials to an external app registry:

      1. To configure Dockerhub.com, add the following registry config block to the end of `cf-values.yml` file:

         ```yml
         app_registry:
           hostname: https://index.docker.io/v1/
           repository_prefix: "<my_username>"
           username: "<my_username>"
           password: "<my_password>"

         ```

         Update `<my_username>` and `<my_password>` with your docker username and password that you created in the above section [Setup docker registry](#setup-a-docker-registry).

      1. To configure a Google Container Registry, add the following registry config block to the end of `cf-values.yml` file:

         ```yml
         app_registry:
           hostname: gcr.io
           repository_prefix: gcr.io/<gcp_project_id>/cf-workloads
           username: _json_key
           password: |
             <contents_of_service_account_json>
         ```

         Update the `gcp_project_id` portion to your GCP Project ID and change `contents_of_service_account_json` to be the entire contents of your GCP Service Account JSON.

1. Generate an "Internal Installation Values" file:

   >  **NOTE:** The script requires the [BOSH CLI](https://bosh.io/docs/cli-v2-install/#install) in installed on your machine. The BOSH CLI is an handy tool to generate self signed certs and passwords.

   ```console
   ./hack/generate-internal-values.sh --values-file ${VALUES_DIR}/cf-values.yml > ${VALUES_DIR}/cf-internal-values.yml
   ```

1. Run the following commands to install Cloud Foundry on your Kubernetes cluster:

      i. Render the final K8s template to raw K8s configuration

         ```console
         ytt -f config -f ${VALUES_DIR}/cf-values.yml -f ${VALUES_DIR}/cf-internal-values.yml > ${VALUES_DIR}/cf-for-k8s-rendered.yml
         ```

      ii. Install using `kapp` and pass the above K8s configuration file

         ```console
         kapp deploy -a cf -f ${VALUES_DIR}/cf-for-k8s-rendered.yml
         ```

   Once you run the command, it should take about 10 minutes or less, depending on your cluster bandwidth and size. `kapp` will provide updates on pending resource creations in the cluster and will wait until all resources are created and running. Here is a sample snippet from `kapp` output:

   ```console
   4:08:19PM: ---- waiting on 1 changes [0/1 done] ----
   4:08:19PM: ok: reconcile serviceaccount/cc-kpack-registry-service-account (v1) namespace: cf-workloads-staging
   4:08:19PM: ---- waiting complete [5/10 done] ----
   ...
   ```

1. Configure DNS on your IaaS provider to point the wildcard subdomain of your system domain and the wildcard subdomain of all apps domains to point to external IP of the Istio Ingress Gateway service. You can retrieve the external IP of this service by running:

   ```console
   kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[*].ip}'
   ```

   OR in certain environments, the external ip may be surfaced as a hostname instead. In that case use:

   ```console
   kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[*].hostname}'
   ```


   > If you used a single DNS record for both `system_domain` and `app_domains`, then have it resolve to the Ingress Gateway's external IP:

   ```console
   # sample A record in Google cloud DNS. The IP address below is the address of Ingress gateway's external IP
   Domain         Record Type  TTL  IP Address
   *.<cf-domain>  A            30   35.111.111.111
   ```

## Validate the deployment

1. Target your CF CLI to point to the new CF instance:

   ```console
   cf api --skip-ssl-validation https://api.<cf-domain>
   ```

   Replace `<cf-domain>` with your desired domain address.

1. Login using the admin credentials for key `cf_admin_password` in `${VALUES_DIR}/cf-values.yml`:

   ```console
   cf auth admin <cf-values.yml.cf-admin_password>
   # or using yq: cf auth admin "$(yq -r '.cf_admin_password' ${VALUES_DIR}/cf-values.yml)"
   ```

1. Create an org/space for your app:

   ```console
   cf create-org test-org
   cf create-space -o test-org test-space
   cf target -o test-org -s test-space
   ```

1. Deploy a source code based app:

   ```console
   cf push test-node-app -p tests/smoke/assets/test-node-app
   ```

   You should see the following output from the above command:
   ```console
   Pushing app test-node-app to org test-org / space test-space as admin...
   Getting app info...
   Creating app with these attributes...

   ... omitted for brevity ...

   type: web
   instances: 1/1
   memory usage: 1024M
   routes: test-node-app.<cf-domain>
   state since cpu memory disk details
   #0 running 2020-03-18T02:24:51Z 0.0% 0 of 1G 0 of 1G
   ```

   </br>

1. Validate the app is reachable over **https**:

   ```console
   curl -k https://test-node-app.<cf-domain>
   ```

   You should see the following output:
   ```console
   Hello World
   ```

## Delete the cf-for-k8s deployment

You can delete the cf-for-k8s deployment by running the following command:

   ```console
   kapp delete -a cf
   ```

## Additional resources
Use the following resources to enable additional features in cf-for-k8s:

- [Setup ingress certs with letsencrypt](platform_operators/setup-ingress-certs-with-letsencrypt.md)
- [Setup static loadbalancer IP](platform_operators/setup-static-loadbalancer-ip.md)
- [Setup an external database](platform_operators/external-databases.md), which we recommend for Production environments
- [Setup an external blobstore](platform_operators/external-blobstore.md)

## Roadmap and milestones
You can find the project roadmap (github project) [here](https://github.com/cloudfoundry/cf-for-k8s/projects/4) and our upcoming milestones [here](https://github.com/cloudfoundry/cf-for-k8s/milestones). Feel free to ask questions in the [#cf-for-k8s channel](https://cloudfoundry.slack.com/archives/CH9LF6V1P) in the CloudFoundry slack or submit new feature requests or issues on this repo.
