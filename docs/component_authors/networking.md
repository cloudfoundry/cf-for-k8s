# Networking Configuration for System Components

## Network Policies

[Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) provide a way to declaritively define how `Pods` are allowed to communicate.

These policies, also known as ["Layer 3" Network Policies](https://en.wikipedia.org/wiki/OSI_model#Layer_3:_Network_Layer) (as opposed to "Layer 7" policy that might be applied by a service mesh), are used by a cluster's [CNI plugin](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/) to configure networking rules at the OS level. Not all CNI plugins support Network Policies and their specific implementation is left up to the plugin (many use `iptables` or `eBPF`).

CF for Kubernetes has a goal for all network communication by System Components to be defined by Network Policies. The majority of these policies can be found in `config/network-policy.yml`.

### Writing Network Policies

Policies can be added by creating a new `NetworkPolicy` resource that selects on a set of `Pods` within a namespace. A namespace starts out allowing all ingress/egress traffic for all `Pods`, but as soon as a `Pod` is selected by _at least one_ `NetworkPolicy` it will deny all traffic that is not explicitly defined. `NetworkPolicies` act as additive allow rules so to open up communication for `Pods` you will need to create new `NetworkPolicy` resources.

For example, `NetworkPolicies` similar to the following rule are already applied in cf-for-k8s and denies all `ingress` and `egress` traffic in the `cf-system` namespace:

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
  - Egress
```


Let's say you are introducing a new component that needs to talk to UAA internally. You need to create `NetworkPolicy` selecting UAA pods with `ingress` rules to allow traffic from your component, by either [creating]("#creating-a-new-networkpolicy") an ingress policy or [updating the existing]("#updating-an-existing-networkpolicy") ingress policy. Then, [you need to create an egress `NetworkPolicy`](#creating-an-egress-networkpolicy-for-your-component) selecting your component pods with `egress` rules to allow traffic to UAA.


#### Creating a new NetworkPolicy
The simplest way to create an allow rule for ingress to UAA from your component
is to add a create a new `NetworkPolicy` resource. Network policy rules are
additive so this rule will be applied _in addition_ to the existing to rule.

So if you are adding a new component that wants to talk to UAA, include a
`NetworkPolicy` similar to this with your installation YAML:

```yaml
---
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: uaa-ingress-from-my-new-component
  namespace: cf-system
spec:
  policyTypes:
  - Ingress
  podSelector:
    matchLabels:
      app.kubernetes.io/name: uaa
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: my-new-component
      namespaceSelector:
        matchLabels:
          cf-for-k8s.cloudfoundry.org/cf-system-ns: ""
```

#### Updating an Existing NetworkPolicy
If you are adding a new core component and think the policy should be part of UAA's default `NetworkPolicy`, you can update the existing policy that looks similar to this:

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

You just need to add an additional element to the `from` array. Something like this:

```yaml
- podSelector:
    matchLabels:
      app.kubernetes.io/name: my-new-component
  namespaceSelector:
    matchLabels:
      cf-for-k8s.cloudfoundry.org/cf-system-ns: ""
```

This configures the UAA `NetworkPolicy` to allow ingress traffic from any `Pod` that has the label `app.kubernetes.io/name=my-new-component` in a namespace with the `cf-for-k8s.cloudfoundry.org/cf-system-ns=""` label.

Once you've tested it and everything works, make a PR to update the `NetworkPolicy` in `config/network-policies.yaml`!

#### Creating an Egress NetworkPolicy for your component
Whether you created a new ingress `NetworkPolicy` for UAA or updated the
existing list of ingress rules, you will still need to create a `NetworkPolicy`
for your own component that allows it to egress to UAA.

```yaml
---
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: my-new-component
  namespace: cf-system
spec:
  policyTypes:
  - Egress
  podSelector:
    matchLabels:
      app.kubernetes.io/name: my-new-component
  egress:
  - to:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: uaa
      namespaceSelector:
        matchLabels:
          cf-for-k8s.cloudfoundry.org/cf-system-ns: ""
```
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
CF for Kubernetes uses Istio's [automatic mTLS](https://istio.io/latest/docs/tasks/security/authentication/authn-policy/#auto-mutual-tls) with a `STRICT` authentication policy. This means that all `Pods` that have an Istio sidecar will require incoming traffic to use mutual TLS.

When you create a new namespace, in order to take advantage of all of Istio's features, and communicate with other `Pods` that Istio sidecars, your namespace must have an `istio-injection=enabled` label to turn on automatic [Sidecar Injection](https://istio.io/latest/docs/setup/additional-setup/sidecar-injection/). This makes it so the pods in your namespace will contain an [Istio sidecar proxy](https://istio.io/latest/docs/reference/config/networking/sidecar/) running alongside them. In CF for Kubernetes, Istio sidecar injection is added automatically by a `ytt` overlay [config/istio/add-istio-injection.yml](https://github.com/cloudfoundry/cf-for-k8s/blob/develop/config/istio/add-istio-injection.yml).

To confirm your namespace has automatic sidecar injection enabled, you can describe your namespace with `kubectl get namespace <namespace_name> -L istio-injection` and see that Istio Injection is set to "enabled".
