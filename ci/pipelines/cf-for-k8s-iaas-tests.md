# cf-for-k8s-iaas-tests

## Purpose

This pipeline provides compatibility information for cf-for-k8s across Kubernetes providers that are not directly supported and validated by the main cf-for-k8s pipelines. At this time, those are: [EKS](https://aws.amazon.com/eks), [AKS](https://azure.microsoft.com/en-us/services/kubernetes-service/), and [Minikube](https://github.com/kubernetes/minikube) running on a [GCE](https://cloud.google.com/compute) virtual machine.

## Validation Strategy

For each IaaS provider, we keep [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)  configuration in the `/deploy` directory of cf-for-k8s. Using these templates, we dynamically provision a Kubernetes environment, install cf-for-k8s, run the smoke-tests in cf-for-k8s, run a subset of [cf-acceptance-tests](https://github.com/cloudfoundry/cf-acceptance-tests), and tear down the environment. We run the jobs in this pipeline informationally on a daily cadence.
