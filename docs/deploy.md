# Deploying Cloud Foundry on a Kubernetes cluster

- [Prerequisites](#prerequisites)
  - [Required Tools](#required-tools)
  - [Kubernetes Cluster Requirements](#kubernetes-cluster-requirements)
  - [IaaS Requirements](#iaas-requirements)
  - [Requirements for pushing source-code based apps to Cloud Foundry foundation](#requirements-for-pushing-source-code-based-apps-to-cloud-foundry-foundation)
- [Known Issues](#knownissues)
- [Steps to deploy](#steps-to-deploy)
  - [Option A - Use the included hack-script to generate the install values](#option-a---use-the-included-hack-script-to-generate-the-install-values)
  - [Option B - Create the install values by hand](#option-b---create-the-install-values-by-hand)
- [Validate the deployment](#validate-the-deployment)
- [Delete the cf-for-k8s deployment](#delete-the-cf-for-k8s-deployment)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

## Prerequisites

### Required Tools

You need the following CLIs on your system to be able to run the script:

- [`cf cli`](https://docs.cloudfoundry.org/cf-cli/install-go-cli.html) (v6.50+)
- [`kapp`](https://k14s.io/#install)
- [`ytt`](https://k14s.io/#install)
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

> Make sure that your Kubernetes config (e.g, `~/.kube/config`) is pointing to the cluster you intend to deploy cf-for-k8s to.

### Kubernetes Cluster Requirements

:exclamation: This project is in it's early stages of development and hence the resource requirements are subject to change in the future. This document and the release notes will be updated accordingly. :exclamation:

To deploy cf-for-k8s as is, the cluster should:

- be running Kubernetes version within range 1.14.x to 1.18.x
- have a minimum of 5 nodes
- have a minimum of 4 CPU, 15GB memory per node
- support `LoadBalancer` services
- support `metrics-server`
  - Most IaaSes come with `metrics-server`, but if yours does not come with it or if you're using `kind`, then you may want to run something like 
  
  ```console
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml
  ```

- defines a default StorageClass
  - requires [additional config on vSphere](https://vmware.github.io/vsphere-storage-for-kubernetes/documentation/storageclass.html), for example

### Requirements for pushing source-code based apps to Cloud Foundry foundation

To be able to push source-code based apps to your cf-for-k8s installation, you will need to add OCI compliant registry (e.g. dockerhub.com) to the configuration.

> Under the hood, cf-for-k8s uses Cloud Native buildpacks to detect and build the app source code into an oci compliant image and pushes the app image to the registry. Though cf-for-k8s has been tested with Google Container Registry and Dockerhub.com, it should work for any external OCI compliant registry.

Currently, we have tested the following two container registries:

- Docker Hub:
  1. Create an account in [dockerhub.com](dockerhub.com). Note down the user name and password you used during signup.
  1. Create a repository in your account. Note down the repository name.

- Google Container Registry:
  1. Create a GCP Service Account with `Storage/Storage Admin` role.
  1. Create a Service Key JSON and download it to the machine from which you will install cf-for-k8s (referred to, below, as `path-to-kpack-gcr-service-account`).

## <a name='knownissues'></a> Known Issues
This project is in it's early stages of development and hence there are features missing. For a list of the known issues, take a look at the [GitHub issues tagged 'known-issue'](https://github.com/cloudfoundry/cf-for-k8s/issues?q=is%3Aissue+is%3Aopen+label%3Aknown-issue).

## Steps to deploy

1. Clone and initialize this git repository:

   ```console
   git clone https://github.com/cloudfoundry/cf-for-k8s.git
   cd cf-for-k8s
   ```

1. Create a "CF Installation Values" file and configure it:

   You can either: a) auto-generate the installation values or b) create the values by yourself.

   #### Option A - Use the included hack-script to generate the install values

   >  **NOTE:** The script requires the [BOSH CLI](https://bosh.io/docs/cli-v2-install/#install) in installed on your machine. The BOSH CLI is an handy tool to generate self signed certs and passwords.

   ```console
   ./hack/generate-values.sh -d <cf-domain> > /tmp/cf-values.yml
   ```

   Replace `<cf-domain>` with _your_ registered DNS domain name for your CF installation.

   #### Option B - Create the install values by hand

   1. Clone file `sample-cf-install-values.yml` from this directory as a starting point.

      ```console
      cp sample-cf-install-values.yml /tmp/cf-values.yml
      ```

   1. Open the file and change the `system_domain` and `app_domain` to your desired domain address.
   1. Generate certificates for the above domains and paste them in `crt`, `key`, `ca` values
      - **IMPORTANT** Your certificates must include a subject alternative name entry for the internal `*.cf-system.svc.cluster.local` domain in addition to your chosen external domain.

1. To enable Cloud Native buildpacks feature, configure access to an external registry in `cf-values.yml`:

   You can choose any of the cloud provider container registries, such as [dockerhub.com](dockerhub.com), [Google container registry](https://cloud.google.com/container-registry), [Azure container registry](https://azure.microsoft.com/en-us/services/container-registry/) and so on. Below are examples for dockerhub or google container registry.

   1. To configure Dockerhub.com

      Add the following registry config block to the end of `cf-values.yml` file.

      ```yml

      app_registry:
         hostname: https://index.docker.io/v1/
         repository: "<my_username>"
         username: "<my_username>"
         password: "<my_password>"

      ```

      1. Update `<my_username>` with your docker username.
      1. Update `<my_password>` with your docker password.

   1. To configure a Google Container Registry, add the following registry config block to the end of `cf-values.yml` file.

      ```yml
      app_registry:
         hostname: gcr.io
         repository: gcr.io/<gcp_project_id>/cf-workloads
         username: _json_key
         password: |
         <contents_of_service_account_json>
      ```

      1. Update the `gcp_project_id` portion to your GCP Project Id.
      1. Change `contents_of_service_account_json` to be the entire contents of your GCP Service Account JSON.

1. Run the following commands to install Cloud Foundry on your Kubernetes cluster.

      i. Render the final K8s template to raw K8s configuration
      ```console
      ytt -f config -f /tmp/cf-values.yml > /tmp/cf-for-k8s-rendered.yml
      ```
      > cf-for-k8s uses [ytt](https://github.com/k14s/ytt) to create and maintain reusable YAML templates. You can visit the ytt [playground](https://get-ytt.io/) to learn more about it's templating features. 
      > In the above command, `ytt` can take a folder e.g. `config` or file via `-f`. See all options by running `ytt help`.
    
      ii. Install using `kapp` and pass the above K8s configuration file
      ```console
      kapp deploy -a cf -f /tmp/cf-for-k8s-rendered.yml -y
      ```
      > cf-for-k8s uses [kapp](https://github.com/k14s/kapp) to manage it's lifecycle. `kapp` will first show you a list of resources it plans to install on the cluster and then will attempt to install those resources. `kapp` will not exit untill all resources are installed and their status is running. See all options by running `kapp help`.

   Once you run the command, it should take about 10 minutes depending on your cluster bandwidth, size. `kapp` will provide updates on pending resource creations in the cluster and will wait until all resources are created and running. Here is a sample snippet from `kapp` output:
   
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

1. Login using the admin credentials for key `cf_admin_password` in `/tmp/cf-values.yml`

   ```console
   cf auth admin <cf-values.yml.cf-admin_password>
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

1. Validate the app is reachable

   ```console
   curl http://test-node-app.<cf-domain>/env
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
