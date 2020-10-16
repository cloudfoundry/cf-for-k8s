# Deploying CF for K8s Locally

- [Prerequisites](#prerequisites)
  * [Required Tools](#required-tools)
  * [Machine Requirements](#machine-requirements)
- [Considerations](#considerations)
- [Steps to Deploy on KinD](#steps-to-deploy-on-kind)
- [Steps to Deploy on Minikube](#steps-to-deploy-on-minikube)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>


## Prerequisites

### Required Tools

See the requirements in [Deploying CF for K8s](deploy.md#required-tools).

### Machine Requirements

In addition to the Kubernetes version requirement in [Deploying CF for K8s](deploy.md#kubernetes-cluster-requirements), the cluster should:

1) Use a Kubernetes version within the supported version window (see `supported_k8s_versions.yml`)

2) Specify at least the minimum resource requirements shown below.

**Minimum Requirements**

- 4 CPU, 6GB memory if using 1 node

**Recommended Requirements**

- 6-8 CPU, 8-16GB memory if using 1 node
- When running with less than recommended requirements it is common for an initial `kapp deploy` to timeout; a successive `kapp deploy` may remedy this.

Configuration Notes:
- When running on a local Docker Desktop this can be configured via `Docker Desktop > Preferences > Resources`.
- When running `Minikube`, resources can be provided as command line arguments to the start command. e.g. `minikube start --cpus=6 --memory=8gb --driver=docker`

## Considerations

1. Using minikube allows local image development via the included docker daemon
   without having to push to a public image registry, whereas KinD uses
   containerd as its backing driver, which doesn't allow for local image
   creation.

1. The docker driver for minikube is significantly faster than the default
   virtualbox driver as it uses the local Docker for Mac installation.

## Steps to Deploy on KinD

0. (Optional) Choose the version of Kubernetes you'd like to use to deploy KinD.

   To grab the latest KinD patch version of a K8s minor release:

   ```console
   # from the cf-for-k8s repo/directory
   k8s_minor_version="$(yq -r .newest_version supported_k8s_versions.yml)"  # or k8s_minor_version="1.17"
   patch_version=$(wget -q https://registry.hub.docker.com/v1/repositories/kindest/node/tags -O - | \
     jq -r '.[].name' | grep -E "^v${k8s_minor_version}.[0-9]+$" | \
     cut -d. -f3 | sort -rn | head -1)
   k8s_version="v${k8s_minor_version}.${patch_version}"
   echo "Creating KinD cluster with Kubernetes version ${k8s_version}"
   ```

1. Create a KinD cluster:

   ```console
   # from the cf-for-k8s repo/directory
   kind create cluster --config=./deploy/kind/cluster.yml
   # suggested flag: "--image kindest/node:${k8s_version}"
   ```

2. Follow the instructions in [Deploying CF for K8s](deploy.md).

   - Use `vcap.me` as the domain for the installation. This means that you do not have to
     configure DNS for the domain.

   - Make sure the following values are included in your install values file:
   ```yaml
   add_metrics_server_components: true
   enable_automount_service_account_token: true
   metrics_server_prefer_internal_kubelet_address: true
   remove_resource_requirements: true
   use_first_party_jwt_tokens: true
   
   load_balancer:
     enable: false
   ```

3. Once the `kapp deploy` succeeds, you should be able to run `cf api api.vcap.me --skip-ssl-validation`, etc

   * If the kapp deploy fails with a message like `Finished unsuccessfully (Deployment is not progressing: ProgressDeadlineExceeded (message: ReplicaSet "something" has timed out progressing.))`, this may indicate that your cluster's resources are under allocated. Simply re-running the kapp deploy command frequently fixes this issue.

## Steps to Deploy on Minikube

1. Start minikube using the docker driver:

   ```console
   minikube start --cpus=6 --memory=8g --kubernetes-version="1.19.2" --driver=docker
   # available minikube K8s versions can be found here: https://github.com/kubernetes/minikube/blob/master/pkg/minikube/constants/constants.go
   # make sure to use a version within the cf-for-k8s supported minor version window (see `supported_k8s_versions.yml`)
   ```

1. Enable metrics-server.

   ```console
   minikube addons enable metrics-server
   ```

1. Obtain minikube IP.

   ```console
   minikube ip
   ```

   - The domain used for the installation will use this IP with the following format `<minikube ip>.nip.io`.  For example if `minikube ip` returns `127.0.0.1` then you domain would be `127.0.0.1.nip.io`

1. Use minikube tunnel to expose the LoadBalancer service for the ingress
   gateway:

   ```console
   sudo minikube tunnel
   ```

   - This should be run in a separate terminal as this will block.
   - `sudo` give capabilities to the tunnel ahead of time to open ports 80 and 443 (required to communicate)
   - The `kapp deploy` command will not exit successfully until this command is
     run to allow minikube to create the LoadBalancer service.

1. Follow the instructions in [Deploying CF for K8s](deploy.md).

   - Use `<minikube ip>.nip.io` as the domain for the installation. This means that you do not have to
     configure DNS for the domain.

   - Make sure you provide an OCI-compliant app registry in your install values file.

   - Make sure the following values are included in your install values file:
   ```yaml
   remove_resource_requirements: true
   enable_automount_service_account_token: true
   use_first_party_jwt_tokens: true
   ```

1. You will be able to target your CF CLI to point to the new CF instance

   ```console
   cf api --skip-ssl-validation https://api.<minikube ip>.nip.io
   ```

1. To access the kubelet's docker engine, run:

   ```console
   eval $(minikube docker-env)
   docker ps
   ...
   ```
