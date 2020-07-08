# Networking Configuration for System Components

## Network Policies

[Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) provide a way to declaritively define how `Pods` are allowed to communicate.

These policies, also known as ["Layer 3" Network Policies](https://en.wikipedia.org/wiki/OSI_model#Layer_3:_Network_Layer) (as opposed to "Layer 7" policy that might be applied by a service mesh), are used by a cluster's [CNI plugin](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/) to configure networking rules at the OS level. Not all CNI plugins support Network Policies and their specific implementation is left up to the plugin (many use `iptables` or `eBPF`).

CF for Kubernetes has a goal for all network communication by System Components to be defined by Network Policies. The majority of these policies can be found in `config/network-policy.yml`.

### Writing Network Policies

Policies can be added by creating a new `NetworkPolicy` resource that selects on a set of `Pods` within a namespace. A namespace starts out allowing all ingress/egress traffic for all `Pods`, but as soon as a `Pod` is selected by _at least one_ `NetworkPolicy` it will deny all traffic that is not explicitly defined. `NetworkPolicies` act as additive allow rules so to open up communication for `Pods` you will need to create new `NetworkPolicy` resources.

Here's an example. The following rule will deny all `ingress` traffic in the `cf-system` namespace:

```yaml
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: cf-system
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

Let's say you are introducing a new component that needs to talk to UAA internally. You see that there is an existing `NetworkPolicy` that selects on UAA with a set of `ingress` rules defined.

```yaml
---
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: uaa
  namespace: cf-system
spec:
  policyTypes:
  - Ingress
  - Egress
  podSelector:
    matchLabels:
      app.kubernetes.io/name: uaa
  ingress:
  - from:
    - podSelector:
        matchLabels:
          istio: ingressgateway
      namespaceSelector:
        matchLabels:
          cf-for-k8s.cloudfoundry.org/istio-system-ns: ""
    - podSelector:
        matchLabels:
          app: log-cache
      namespaceSelector:
        matchLabels:
          cf-for-k8s.cloudfoundry.org/cf-system-ns: ""
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: cf-api-server
      namespaceSelector:
        matchLabels:
          cf-for-k8s.cloudfoundry.org/cf-system-ns: ""
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: cf-api-kpack-watcher
      namespaceSelector:
        matchLabels:
          cf-for-k8s.cloudfoundry.org/cf-system-ns: ""
  egress:
  - {}
```

To configure the UAA `Pod` to allow ingress traffic from your new component, you would add an additional element to the `from` array. Something like this:

```
- podSelector:
    matchLabels:
      app.kubernetes.io/name: my-new-component
  namespaceSelector:
    matchLabels:
      cf-for-k8s.cloudfoundry.org/cf-system-ns: ""
```

This configures the UAA `NetworkPolicy` to allow ingress traffic from any `Pod` that has the label `app.kubernetes.io/name=my-new-component` in a namespace with the `cf-for-k8s.cloudfoundry.org/cf-system-ns=""` label.

Once you've tested it and everything works, make a PR to update the `NetworkPolicy` in `config/network-policies.yaml`!

### Namespaces and Network Policies
`NetworkPolicies` apply to `Pods` within a **single namespace**.

If you're creating a new namespace we highly recommend creating an initial ["default deny all"](https://kubernetes.io/docs/concepts/services-networking/network-policies/#default-deny-all-ingress-and-all-egress-traffic) `NetworkPolicy` to block all ingress and egress traffic to `Pods` in the namespace.

```yaml
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: YOUR_NAMESPACE_NAME
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

Then add in the appropriate `allow` rules through additional `NetworkPolicies`.


## Istio Sidecar Injection

### Namespaces and Istio Sidecar Injection
CF for Kubernetes uses Istio's [automatic mTLS](https://istio.io/latest/docs/tasks/security/authentication/authn-policy/#auto-mutual-tls) with a `STRICT` authentication policy. This means that all `Pods` that have an Istio sidecar will require any `Pods` that communicate with them to also have an Istio sidecar and use mutual TLS to secure traffic. Traffic that doesn't use mTLS or traffic that does not come from an Istio sidecar will be rejected and the connection will fail.

When you create a new namespace, in order to take advantage of all of Istio's features, and communicate with other `Pods` that Istio sidecars, your namespace must have an `istio-injection=enabled` label to turn on automatic [Sidecar Injection](https://istio.io/latest/docs/setup/additional-setup/sidecar-injection/). This makes it so the pods in your namespace will contain an [Istio sidecar proxy](https://istio.io/latest/docs/reference/config/networking/sidecar/) running alongside them. In CF for Kubernetes, Istio sidecar injection is added automatically by a `ytt` [overlay](https://github.com/cloudfoundry/cf-for-k8s/blob/master/config/networking.yml#L63).

To confirm your namespace has automatic sidecar injection enabled, you can describe your namespace with `kubectl get namespace <namespace_name> -L istio-injection` and see that Istio Injection is set to "enabled".

If for some reason, sidecar injection is not enabled automatically in your namespace, you can manually add it by adding the following label to your namespace `kubectl label namespace <namespace_name> istio-injection=enabled`.
