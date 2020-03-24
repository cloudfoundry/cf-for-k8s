# Deploying CF for K8s Locally

- [Prerequisites](#prerequisites)
- [Considerations](#considerations)
- [Steps to Deploy on Minikube](#steps-to-deploy-on-minikube)
- [Steps to Deploy on Kind](#steps-to-deploy-on-kind)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

## Prerequisites

### Required Tools

See the requirements in [Deploying CF for K8s](deploy.md#required-tools).

### Machine Requirements

In addition to the Kubernetes version requirement in [Deploying CF for K8s](deploy.md#kubernetes-cluster-requirements), the cluster should:

* have a minimum of 1 node
* have a minimum of 4 CPU, 8GB memory per node

## Considerations

1. Using minikube allows local image development via the included docker daemon
   without having to push to a public image registry, whereas kind uses
   containerd as its backing driver, which doesn't allow for local image
   creation.

1. The docker driver for minikube is significantly faster than the default
   virtualbox driver as it uses the local Docker for Mac installation.

## Steps to Deploy on Minikube

1. Start minikube using the docker driver:
   ```bash
   $ minikube start --cpus=4 --memory=8g --kubernetes-version=1.15.7 --driver=docker
   ```

1. Follow the instructions in [Deploying CF for K8s](deploy.md).
   * Include the [remove-resource-requirements.yml](../config-optional/remove-resource-requirements.yml)
     overlay file in the set of templates to be deployed. This can be achieved by
     using the following command instead of running the install-cf.sh script:
     
     ```bash
     $ kapp deploy -a cf -f <(ytt -f config -f <cf_install_values_path> -f config-optional/remove-resource-requirements.yml)
     ```
   * Use `vcap.me` as the domain for the installation. This means that you do not have to
    configure DNS for the domain.
   
1. Use minikube tunnel to expose the LoadBalancer service for the ingress
   gateway:
   ```bash
   $ minikube tunnel
   ```
   * This should be run in a separate terminal as this will block.
   * The `install-cf.sh` script will not exit successfully until this command is
     run to allow minikube to create the LoadBalancer service.

1. To access the kubelet's docker engine, run:
   ```bash
   $ eval $(minikube docker-env)
   $ docker ps
   ...
   ```

## Steps to Deploy on Kind

1. Create a kind cluster:
   ```bash
   $ kind create cluster --config=./deploy/kind/cluster.yml
   ```

1. Follow the instructions in [Deploying CF for K8s](deploy.md).
   * Include the [remove-resource-requirements.yml](../config-optional/remove-resource-requirements.yml) and
     [use-nodeport-for-ingress.yml](../config-optional/use-nodeport-for-ingress.yml)
     overlay files in the set of templates to be deployed. This can be achieved by
     using the following command instead of running the install-cf.sh script:
     ```bash
     $ kapp deploy -a cf -f <(ytt -f config -f <cf_install_values_path> -f config-optional/remove-resource-requirements.yml -f config-optional/use-nodeport-for-ingress.yml)
     ```
   * Use `vcap.me` as the domain for the installation. This means that you do not have to
     configure DNS for the domain.
