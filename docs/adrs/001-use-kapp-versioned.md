# 1. Use kapp versioned annotation

Date: 2020-05-08

[Tracker ID: [#167379966](https://www.pivotaltracker.com/story/show/167379966)]
https://www.pivotaltracker.com/story/show/172597153
https://www.pivotaltracker.com/story/show/172597361
https://www.pivotaltracker.com/story/show/172724542

## Status

Accepted

## Context

As we look to support the rotation of configuration and credentials in cf-for-k8s,
we have considered the potential challenges of a kubernetes-native implementation. At
some point in the chain from kubernetes resources to the processes running in pods, we need
to update a value and have that value flow into the running processes by which it
is consumed.

As an initial callout, we have the following underlying assumption:
hardcoding the value of a secret into config and updating it there is not a secure solution.
Instead we would like to capture configuration and values in kubernetes
primitives, ConfigMaps and Secrets, and only consume references to those resources.
Consequently our only option for updating the value itself is to update the ConfigMap or Secret.
This leaves the question of how we update all of the consumers of those resources?

### Examples to illustrate our assumption and the top level update mechanism

#### Hardcoded insecure examples:
kind: ConfigMap
  metadata:
    name: my-insecure-configmap
  hardcoded-secret: my-other-secret

kind: Pod
  env:
    name: hardcoded-secret
    value: my-secret
  volumeMounts:
  - name: config-vol
    mountPath: /etc/config
  volumes:
  - name: config-vol
    configMap:
      name: my-insecure-configmap
      items:
      - key: hardcoded-secret
        path: hardcoded-secret

An update mechanism would be responsible for finding every instance of the
secret values: 'my-secret' and 'my-other-secret' and updating them directly in
plaintext on the kubernetes resources yaml.

#### Secure reference example:
kind: Secret
  metadata:
    name: secure-example
    stringData: my-secure-secret

kind: Pod
  volumeMounts:
  - name: config-vol
    mountPath: /etc/config
  volumes:
  - name: secure-secret
    secret:
      name: secure-example

An update mechanism would now only be responsible for updating the kubernetes
Secret value directly.

### Propagating the updated value in both cases:
An update mechanism would be responsible for finding every runtime use of the
secret reference and triggering the value to update. The cluster kubelet handles
the update of secrets on containers on some configurable interval for instance.

We could take advantage of the standard kubernetes initialization
lifecycle to both update and load the updated secret by restarting the running containers with a
pod update or something of that nature. Alternatively, the runtime itself could
be responsible for detecting changes to the mounted secrets and reloading after
the kubelet periodically remounts the volumes with updated contents.

### Intermediate References:
In some cases, Secrets and ConfigMaps are referred to by other resources above
the pod/container level. If we happen to be updating the reference
itself, we would also need a mechanism for updating every consuming resource with a
reference to the original resource.

## Decision

Use kapp and the kapp versioned annotation to manage the update of all Secrets and
ConfigMaps in cf-for-k8s.

See https://github.com/k14s/kapp/blob/ebed3116baac6a0e414648e6a93d3cc946c7fe91/docs/diff.md#versioned-resources

## Consequences

By default, kapp is configured to detect all references to Secrets and
ConfigMaps in the core Kubernetes API resources. (And if any are missing, please
PR them into the default kapp templateRules). For all CRDs with references to
Secrets and Configmaps, we need to add a custom templateRule entry matching
the resource and the path to the reference within that resource.
