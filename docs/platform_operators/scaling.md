- [Scaling cf-for-k8s](#scaling-cf-for-k8s)
  * [Horizontal Scaling](#horizontal-scaling)
  * [Vertical Scaling](#vertical-scaling)
  * [Discovering all cf-for-k8s Pods](#discovering-all-cf-for-k8s-pods)
  * [Component-specific Scaling](#component-specific-scaling)
    + [Scaling CF API](#scaling-cf-api)
    + [Scaling Networking](#scaling-networking)
  * [ytt overlay troubleshooting](#ytt-overlay-troubleshooting)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

# Scaling cf-for-k8s

cf-for-k8s ships by default in a small-footprint, developer configuration to allow for quick testing, for example on a minikube or KinD local cluster. For production use cases, cf-for-k8s needs to be scaled up. This document describes different ways of scaling cf-for-k8s and gives examples that you can use as a starting point.

## Horizontal Scaling

This involves changing the number of Kubernetes _pods_ (where a pod is where containers are run) that a particular component uses.

For example, suppose you want to be running 3 `cf-api-server` pods instead of the default of 2.

The easiest way is to create a _ytt overlay_ that makes this specification. Suppose it's in the file called `scale-api-server.yml` (it's important that this file have a `.yml` extension):

```yaml
#@ load("@ytt:overlay", "overlay")
---
#@overlay/match by=overlay.subset({"kind": "Deployment", "metadata":{"name": "cf-api-server"}})
---
spec:
  replicas: 3
```

You then modify the `ytt` command to include this file as an additional `-f` input:
```bash
$ ytt -f config -f VALUES_FILE -f scale-api-server.yml > /tmp/new-cffork8s-rendered.yml
```

If you had run an earlier `ytt` command, you should see this diff in the rendered contents:
```bash
$ ytt -f config -f VALUES_FILE > /tmp/cffork8s-rendered.yml
$ ytt -f config -f VALUES_FILE -f scale-api-server.yml > /tmp/new-cffork8s-rendered.yml
$ diff /tmp/cffork8s-rendered.yml /tmp/new-cffork8s-rendered.yml
38c38
<   replicas: 2
---
>   replicas: 3
```

You can learn much more about `ytt`, and try things out in the `ytt sandbox` at https://get-ytt.io .

## Vertical Scaling

This section is concerned with two resources: the amount of RAM and how much of a CPU a container has access to.

By default, a container has no resource constraints placed on it.

When a container is run, a command like `docker run` can specify the amount of memory and/or CPU the container has access to. In `cf-for-k8s`, containers are run through YAML specifications in the `spec.containers.resources` fields. For example, in `config/capi/_ytt_lib/capi-k8s-release/templates/api_server_deployment.yml`, the starting and maximum limits for each `cf-api-server` container are specified as:

```yaml
  resources:
    requests:
      cpu: 500m
      memory: 300Mi
    limits:
      cpu: 1000m
      memory: 1.2Gi
```

The `requests` block gives the initial resources for the container, and the `limits` gives the final. If a container exceeds a factor in the `limits` block, kubernetes kills that container and starts a new one. This is called [burstable QOS](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/) (quality of service), and is normally the best way to configure pods. See this wonderful, succinct blog post to learn more: [The Kubernetes Quality of Service Conundrum](https://medium.com/better-programming/the-kubernetes-quality-of-service-conundrum-eebbbb5f89cf)

You _could_ modify this file in place, but it's better to write a reusable `ytt` overlay to scale. All your overlays could be in a single file, but we'll write this one in a separate file, `vertically-scale-api-server.yml`, to isolate the change:

```yaml
#@ load("@ytt:overlay", "overlay")
---
#@overlay/match by=overlay.subset({"kind": "Deployment", "metadata":{"name": "cf-api-server"}})
---
spec:
  template:
    spec:
      containers:
      #@overlay/match by=overlay.subset({"name": "cf-api-server"})
      - resources:
          limits:
            cpu: 2000m
            memory: 2.4Gi
```

The syntax might be unfamiliar, but it's essentially describing a path through the yaml tree (`kind.spec.template.spec.containers`) using the two `overlay/match` commands to select the particular items we want. Again, see https://get-ytt.io for more info.

This time, comparing the new and old rendered contents should give this diff:

```bash
$ ytt -f config -f VALUES_FILE -f vertically-scale-api-server.yml > /tmp/new-rendered-contents.yml
$ diff /tmp/rendered-contents.yml /tmp/new-rendered-contents.yml
70,71c70,71
<             cpu: 1000m
<             memory: 1.2Gi
---
>             cpu: 2000m
>             memory: 2.4Gi
```

## Discovering all cf-for-k8s Pods

`cf-for-k8s` puts pods in several different namespaces, so the most straightforward way to list all the pods that can be scaled up is by ignoring the kubernetes pods, with this command:

```bash
$ kubectl get pods -A | grep -v -e kube-system -e cf-workloads
```

Note: The `cf-workloads` namespace is controlled by `cf-for-k8s` internals, and should not require scaling.

## Component-specific Scaling

### Scaling CF API

Please see https://docs.cloudfoundry.org/running/managing-cf/scaling-cloud-controller-k8s.html

### Scaling Networking

This describes how to scale the cf-for-k8s networking components for production use cases. It uses the ideas and principles described above and includes an example overlay implementation.

If you would like to scale up the networking components for a larger scale
environment, simply:
1. Copy the following example into a `scaling-networking.yml` file
1. Adjust the values to your liking
1. Append `-f scaling-networking.yml` to the `ytt` command you run for rendering your cf-for-k8s yaml

The number of ingressgateway replicas depends on load profile of your cluster. Based on the Istio team's testing, in an unknown test environment, a single Envoy consumes 0.5 vCPU and 50 MB memory per 1000 requests per second.

The number of istiod replicas depends on the number of application instances.

We recommend two routecontrollers for high availability; you likely won't
need more than that.

Sidecar resource usage depends on the load profile of your AIs.

```yaml
#@ load("@ytt:overlay", "overlay")
#@ load("@ytt:json", "json")
#! Modify these values to adjust scaling characteristics
#@ ingress_gateway_replicas = 2
#@ ingress_gateway_cpu_request = "1"
#@ ingress_gateway_cpu_limit = "2"
#@ ingress_gateway_mem_request = "1Gi"
#@ ingress_gateway_mem_limit = "2Gi"
#@ istiod_replicas = 2
#@ istiod_cpu_request = "1"
#@ istiod_cpu_limit = "2"
#@ istiod_mem_request = "1Gi"
#@ istiod_mem_limit = "2Gi"
#@ routecontroller_replicas = 2
#@ routecontroller_cpu_request = "200m"
#@ routecontroller_cpu_limit = "400m"
#@ routecontroller_mem_request = "32Mi"
#@ routecontroller_mem_limit = "1024Mi"
#@ sidecar_cpu_request = "100m"
#@ sidecar_cpu_limit = "2000m"
#@ sidecar_mem_request = "128Mi"
#@ sidecar_mem_limit = "1024Mi"

#! the intent is that the overlays below shouldn't need to be changed [much] but we are not testing them in CI
#! if you notice that they've become outdated, please suggest changes via a pull request

#@ def modify_configmap(data):
#@   decoded = json.decode(data)
#@   decoded["global"]["proxy"]["resources"] = {
#@     "limits": {
#@       "cpu": sidecar_cpu_limit,
#@       "memory": sidecar_mem_limit,
#@     },
#@     "requests": {
#@       "cpu": sidecar_cpu_request,
#@       "memory": sidecar_mem_request,
#@     },
#@   }
#@   return json.encode(decoded)
#@ end

#@overlay/match by=overlay.subset({"kind": "ConfigMap", "metadata":{"name":"istio-sidecar-injector"}}),expects=1
---
data:
  #@overlay/replace via=lambda a,_: modify_configmap(a)
  values:

#@overlay/match by=overlay.subset({"kind": "DaemonSet", "metadata":{"name":"istio-ingressgateway"}}),expects=1
---
#@overlay/replace
kind: Deployment
spec:
  #@overlay/match missing_ok=True
  replicas: #@ ingress_gateway_replicas
  template:
    spec:
      containers:
      #@overlay/match by="name", expects=1
      - name: istio-proxy
        #@overlay/match missing_ok=True
        resources:
          limits:
            cpu: #@ ingress_gateway_cpu_limit
            memory: #@ ingress_gateway_mem_limit
          requests:
            cpu: #@ ingress_gateway_cpu_request
            memory: #@ ingress_gateway_mem_request

#@overlay/match by=overlay.subset({"kind": "Deployment", "metadata":{"name":"istiod"}}),expects=1
---
spec:
  #@overlay/replace
  replicas: #@ istiod_replicas
  template:
    spec:
      containers:
      #@overlay/match by="name", expects=1
      - name: discovery
        #@overlay/match missing_ok=True
        #@overlay/replace
        resources:
          limits:
            cpu: #@ istiod_cpu_limit
            memory: #@ istiod_mem_limit
          requests:
            cpu: #@ istiod_cpu_request
            memory: #@ istiod_mem_request

#@overlay/match by=overlay.subset({"kind": "Deployment", "metadata": { "name": "routecontroller"}}),expects=1
---
spec:
  #@overlay/replace
  replicas: #@ routecontroller_replicas
  template:
    spec:
      containers:
      #@overlay/match by="name", expects=1
      - name: routecontroller
        #@overlay/match missing_ok=True
        resources:
          limits:
            cpu: #@ routecontroller_cpu_limit
            memory: #@ routecontroller_mem_limit
          requests:
            cpu: #@ routecontroller_cpu_request
            memory: #@ routecontroller_mem_request
```

## ytt overlay troubleshooting

`ytt` *will* give error messages if it finds a problem in some code. If there is no problem, it will emit over 16,000 lines of YAML. Normally, when you run `ytt` you should direct its output to a file, as we've done in the above examples. If there's an error, the message will be written to `stderr` and not to the redirected file. For example, let's rerun the vertical scaling example with one small change in the overlay code, saved in a file called `vertically-scale-api-server-missing-list-hyphen.yml`:


```yaml
#@ load("@ytt:overlay", "overlay")
---
#@overlay/match by=overlay.subset({"kind": "Deployment", "metadata":{"name": "cf-api-server"}})
---
spec:
  template:
    spec:
      containers:
      #@overlay/match by=overlay.subset({"name": "cf-api-server"})
      resources:  #! <---- missing hyphen before 'resources'
          limits:
            cpu: 2000m
            memory: 2.4Gi
```

```bash
$ ytt -f config -f VALUES_FILE -f vertically-scale-api-server-missing-list-hyphen.yml  > output.txt
  ytt: Error: Overlaying (in following order: 2-fix-null-annotations.yml, capi/staging-ns-label.yml, eirini/eirini.yml, fix-db-startup-order.yml, istio/add-istio-injection.yml, istio/external-routing.yml, istio/istio-kapp-ordering.yml, istio/label-istio-ns.yml, istio/remove-hpas-and-scale-istiod.yml, kpack/kapp-order.yml, kpack/kpack-ns-label.yml, kpack/kpack.yml, minio/minio.yml, networking/network-policies.yaml, postgres/postgres.yml, prioritize-daemonsets.yml, uaa/uaa.yml, workloads-namespace.yml, z-kapp-versioned-creds.yml, vert-scale-api-server.yml):
    Document on line vert-scale-api-server.yml:4:
      Map item (key 'spec') on line vert-scale-api-server.yml:5:
        Map item (key 'template') on line vert-scale-api-server.yml:6:
          Map item (key 'spec') on line vert-scale-api-server.yml:7:
            Map item (key 'resources') on line vert-scale-api-server.yml:10:
              Expected number of matched nodes to be 1, but was 0

```
