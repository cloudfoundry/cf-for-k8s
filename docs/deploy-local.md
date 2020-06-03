# Deploying CF for K8s Locally

- [Prerequisites](#prerequisites)
  * [Required Tools](#required-tools)
  * [Machine Requirements](#machine-requirements)
- [Considerations](#considerations)
- [Steps to Deploy on Kind](#steps-to-deploy-on-kind)
- [Steps to Deploy on Minikube](#steps-to-deploy-on-minikube)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>


## Prerequisites

### Required Tools

See the requirements in [Deploying CF for K8s](deploy.md#required-tools).

### Machine Requirements

In addition to the Kubernetes version requirement in [Deploying CF for K8s](deploy.md#kubernetes-cluster-requirements), the cluster should:

- have a minimum of 6 CPU, 6GB memory if using 1 node
  - commonly configured via Docker Desktop > Preferences > Resources
- have a running metrics-server (this is an important consideration for **Kind** or **kubeadm** clusters. You can see one way to install it in the [Kind deploy instructions](#steps-to-deploy-on-kind))

## Considerations

1. Using minikube allows local image development via the included docker daemon
   without having to push to a public image registry, whereas kind uses
   containerd as its backing driver, which doesn't allow for local image
   creation.

1. The docker driver for minikube is significantly faster than the default
   virtualbox driver as it uses the local Docker for Mac installation.

## Steps to Deploy on Kind

   - Use `vcap.me` as the domain for the installation. This means that you do not have to
     configure DNS for the domain.

1. Create a kind cluster:

   ```console
   kind create cluster --config=./deploy/kind/cluster.yml
   # optional flag: "--image kindest/node:v1.18.2", for example
   ```

1. Follow the instructions in [Deploying CF for K8s](deploy.md).

   - Include the [remove-resource-requirements.yml](../config-optional/remove-resource-requirements.yml) and
     [remove-ingressgateway-service.yml](../config-optional/remove-ingressgateway-service.yml)
     overlay files in the set of templates to be deployed. This can be achieved by
     using the following commands:

     ```console
     ytt -f config -f config-optional/remove-resource-requirements.yml -f config-optional/remove-ingressgateway-service.yml -f <cf_install_values_path> > /tmp/cf-for-k8s-rendered.yml
     kapp deploy -a cf -f /tmp/cf-for-k8s-rendered.yml -y
     ```

1. Make sure you've installed a metrics-server.
   - this may be as simple as running something like `kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml`

1. Once the `kapp deploy` succeeds, you should be able to run `cf api api.vcap.me --skip-ssl-validation`, etc

## Steps to Deploy on Minikube

1. Start minikube using the docker driver:

   ```console
   minikube start --cpus=4 --memory=8g --kubernetes-version=1.16.8 --driver=docker
   ```

1. Obtain minikube IP.

   ```console
   minikube ip
   ```

   - The domain used for the installation will use this IP with the following format `<minikube ip>.nip.io`.

1. Use minikube tunnel to expose the LoadBalancer service for the ingress
   gateway:

   ```console
   minikube tunnel
   ```

   - This should be run in a separate terminal as this will block.
   - The `kapp deploy` command will not exit successfully until this command is
     run to allow minikube to create the LoadBalancer service.

1. Follow the instructions in [Deploying CF for K8s](deploy.md).
   - Use `<minikube ip>.nip.io` as the domain for the installation. This means that you do not have to
     configure DNS for the domain.
   - Include the [remove-resource-requirements.yml](../config-optional/remove-resource-requirements.yml)
     overlay file in the set of templates to be deployed. This can be achieved by
     using the following commands:

     ```console
     ytt -f config -f config-optional/remove-resource-requirements.yml -f <cf_install_values_path> > /tmp/cf-for-k8s-rendered.yml
     kapp deploy -a cf -f /tmp/cf-for-k8s-rendered.yml -y
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
