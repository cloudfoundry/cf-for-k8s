# Deploying Cloud Foundry on a Kubernetes cluster

- [Prerequisites](#prerequisites)
  - [Required Tools](#required-tools)
  - [Kubernetes Cluster Requirements](#kubernetes-cluster-requirements)
  - [Setup docker registry](#setup-a-docker-registry)
- [Steps to deploy](#steps-to-deploy)
  - [Option A - Use the included hack-script to generate the install values](#option-a---use-the-included-hack-script-to-generate-the-install-values)
  - [Option B - Create the install values by hand](#option-b---create-the-install-values-by-hand)
- [Validate the deployment](#validate-the-deployment)
- [Delete the cf-for-k8s deployment](#delete-the-cf-for-k8s-deployment)
- [Additional Resources](#additional-resources)
- [Roadmap and milestones](#roadmap-and-milestones)

## Prerequisites

### Required Tools

You need the following CLIs on your system to be able to run the script:

- [`cf cli`](https://docs.cloudfoundry.org/cf-cli/install-go-cli.html) (v6.50+)
- [`kapp`](https://k14s.io/#install)
- [`ytt`](https://k14s.io/#install)
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

> Make sure that your Kubernetes config (e.g, `~/.kube/config`) is pointing to the cluster you intend to deploy cf-for-k8s to.

### Kubernetes Cluster Requirements

To deploy cf-for-k8s as is, the cluster should:

- be running Kubernetes version within range 1.16.x to 1.17.x
- have a minimum of 5 nodes
- have a minimum of 4 CPU, 15GB memory per node
- support `LoadBalancer` services
- support `metrics-server`
  - Most IaaSes come with `metrics-server`, but if yours does not come (for example, if you are using `kind`), you will need to include `add_metrics_server_components: true` in your values file.
- defines a default StorageClass
  - requires [additional config on vSphere](https://vmware.github.io/vsphere-storage-for-kubernetes/documentation/storageclass.html), for example

### Setup a docker registry

To be able to push source-code based apps to your cf-for-k8s installation, you will need to add OCI compliant registry (e.g. hub.docker.com) to the configuration.

[hub.docker.com](https://hub.docker.com/) is pretty easy to get started
  1. Create an account in [hub.docker.com](https://hub.docker.com/). Note down the user name and password you used during signup.
  1. Create a repository in your account. Note down the repository name.

## Steps to deploy

1. Clone and initialize this git repository:

   ```console
   git clone https://github.com/cloudfoundry/cf-for-k8s.git
   cd cf-for-k8s
   TMP_DIR=<your-tmp-dir-path> ; mkdir -p ${TMP_DIR}
   ```

1. Create a "CF Installation Values" file and configure it<a name="cf-values"></a>:

   You can either: a) auto-generate the installation values or b) create the values by yourself.

   #### Option A - Use the included hack-script to generate the install values

   >  **NOTE:** The script requires the [BOSH CLI](https://bosh.io/docs/cli-v2-install/#install) in installed on your machine. The BOSH CLI is an handy tool to generate self signed certs and passwords.

   ```console
   ./hack/generate-values.sh -d <cf-domain> > ${TMP_DIR}/cf-values.yml
   ```

   Replace `<cf-domain>` with _your_ registered DNS domain name for your CF installation.

   #### Option B - Create the install values by hand

   1. Clone file `sample-cf-install-values.yml` from this directory as a starting point.

      ```console
      cp sample-cf-install-values.yml ${TMP_DIR}/cf-values.yml
      ```

   1. Open the file and change the `system_domain` and `app_domain` to your desired domain address.
   1. Generate certificates for the above domains and paste them in `crt`, `key`, `ca` values
      - **IMPORTANT** Your certificates must include a subject alternative name entry for the internal `*.cf-system.svc.cluster.local` domain in addition to your chosen external domain.

1. To enable Cloud Native buildpacks feature, configure access to an external dockerhub registry in `cf-values.yml` you setup above in the section **Setup a a docker registry**

      ```yml

      app_registry:
        hostname: https://index.docker.io/v1/
        repository_prefix: "<my_username>"
        username: "<my_username>"
        password: "<my_password>"

      ```

      1. Update `<my_username>` with your docker username.
      1. Update `<my_password>` with your docker password.

1. Run the following commands to install Cloud Foundry on your Kubernetes cluster.

      i. Render the final K8s template to raw K8s configuration
      ```console
      ytt -f config -f ${TMP_DIR}/cf-values.yml > ${TMP_DIR}/cf-for-k8s-rendered.yml
      ```

      ii. Install using `kapp` and pass the above K8s configuration file
      ```console
      kapp deploy -a cf -f ${TMP_DIR}/cf-for-k8s-rendered.yml -y
      ```

   Once you run the command, it should take about ~5-7 minutes depending on your cluster bandwidth, size. `kapp` will provide updates on pending resource creations in the cluster and will wait until all resources are created and running. Here is a sample snippet from `kapp` output:

   ```console
   4:08:19PM: ---- waiting on 1 changes [0/1 done] ----
   4:08:19PM: ok: reconcile serviceaccount/cc-kpack-registry-service-account (v1) namespace: cf-workloads-staging
   4:08:19PM: ---- waiting complete [5/10 done] ----
   ...
   ```

1. Configure DNS on your IaaS provider to point the wildcard subdomain of your system domain and the wildcard subdomain of all apps domains to point to external IP of the Istio Ingress Gateway service. You can retrieve the external IP of this service by running

   ```console
   kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[*].ip}'
   ```

   OR in certain environments, the external ip may be surfaced as a hostname instead. In that case use:

   ```console
   kubectl get svc -n istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[*].hostname}'
   ```


   > If you used a single DNS record for both `system_domain` and `app_domains`, then have it resolve to the Ingress Gateway's external IP

      e.g.

      ```console
      # sample A record in Google cloud DNS. The IP address below is the address of Ingress gateway's external IP
      Domain         Record Type  TTL  IP Address
      *.<cf-domain>  A            30   35.111.111.111
      ```

## Validate the deployment

1. Target your CF CLI to point to the new CF instance

   ```console
   cf api --skip-ssl-validation https://api.<cf-domain>
   ```

   Replace `<cf-domain>` with your desired domain address.

1. Login using the admin credentials for key `cf_admin_password` in `${TMP_DIR}/cf-values.yml`

   ```console
   cf auth admin <cf-values.yml.cf-admin_password>
   # or using yq: cf auth admin "$(yq -r '.cf_admin_password' ${TMP_DIR}/cf-values.yml)"
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

   ```console
   Pushing app test-node-app to org test-org / space test-space as admin...
   Getting app info...
   Creating app with these attributes...

   name: test-node-app
   path: /Users/pivotal/workspace/cf-for-k8s/tests/smoke/assets/test-node-app
   routes: test-node-app.<cf-domain>

   Creating app test-node-app...
   Mapping routes...
   Comparing local files to remote cache...
   Packaging files to upload...
   Uploading files...

   .... logs omitted for brevity


   Waiting for app to start...

   name: test-node-app
   requested state: started
   isolation segment: placeholder
   routes: test-node-app.<cf-domain>
   last uploaded: Tue 17 Mar 19:24:21 PDT 2020
   stack:
   buildpacks:

   type: web
   instances: 1/1
   memory usage: 1024M
   state since cpu memory disk details
   #0 running 2020-03-18T02:24:51Z 0.0% 0 of 1G 0 of 1G
   ```

   </br>

1. Validate the app is reachable over **https**

   ```console
   # for self-signed certs, use -k to allow insecure server connections when using SSL
   curl -k https://test-node-app.<cf-domain>
   ```

   ```console
   Hello World
   ```

## Delete the cf-for-k8s deployment

You can delete the cf-for-k8s deployment by running the following command.

   ```console
   # Assuming that you ran `kapp deploy -a cf...`
   kapp delete -a cf
   ```

## Additional resources
Use the following resources to enable additional features in cf-for-k8s.

- [Setup ingress certs with letsencrypt](platform_operators/setup-ingress-certs-with-letsencrypt.md)
- [Setup static loadbalancer IP](platform_operators/setup-static-loadbalancer-ip.md)
- [Setup an external database](platform_operators/external-databases.md)

## Roadmap and milestones
Please take a moment to review the [roadmap](https://github.com/cloudfoundry/cf-for-k8s/projects/4) and our upcoming [milestones](https://github.com/cloudfoundry/cf-for-k8s/milestones). Feel free to ask questions or submit new feature requests or issues.

