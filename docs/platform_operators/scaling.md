# Scaling cf-for-k8s

Cf-for-k8s ships in a developer configuration to allow quick testing on a first pass, on for example minicube or kind running locally. Chances are in production, it should run at a larger scale. This document defines different ways of scaling cf-for-k8s and gives examples that you can use immediately.

## Horizontal Scaling

This involves changing the number of Kubernetes _pods_ (where a pod is where containers are run) that a particular component uses.

For example, suppose you want to be running 3 `cf-api-server` pods. By default, kubernetes will run 2 api-server pods.

The easiest way is to create a _ytt overlay_ that makes this specification. Suppose it's in the file called `scale-api-server.yml` (and it's important that this file have a `.yml` extension):

```yaml
#@ load("@ytt:overlay", "overlay")
---
#@overlay/match by=overlay.subset({"kind": "Deployment", "metadata":{"name": "cf-api-server"}})
---
spec:
  replicas: 3
```

You then modify the `ytt` command to include this file:
```bash
$ ytt -f config -f VALUES_FILE -f scale-api-server.yml > /tmp/new-rendered-contents.yml
```

If you had run an earlier `ytt` command, you should see this diff in the rendered contents:
```bash
$ ytt -f config -f VALUES_FILE > /tmp/rendered-contents.yml
$ ytt -f config -f VALUES_FILE -f scale-api-server.yml > /tmp/new-rendered-contents.yml
$ diff /tmp/rendered-contents.yml /tmp/new-rendered-contents.yml
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

The `requests` block gives the initial resources for the container, and the `limits` gives the final. If a container exceeds a factor in the `limits` block, kubernetes kills that container and starts a new one. This is called burstable [QOS](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/) (quality of service), and is normally the best way to configure pods.

You _could_ modify this file in place, but then you would lose a record of the changes you make to the configuration. Once again, it's better to write a `ytt` overlay to scale. All your overlays could be in a single file, but we'll write this one in a separate file, `vertically-scale-api-server.yml`, to isolate the change:

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

The syntax might look unfamiliar, but it's essentially describing a path through the yaml tree (`kind.spec.template.spec.containers`) using the two `overlay/match` commands to select the particular items we want. Again, see https://get-ytt.io for more info.

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

## Discovering the cf-for-k8s Pods

`cf-for-k8s` puts pods in several different namespaces, so the most straightforward way to list all the pods that can be scaled up is by ignoring the kubernetes pods, with this command:

```bash
$ kubectl get pods -A | grep -v -e kube-system -e cf-workloads
```

Initially the `cf-workloads` namespace will be empty, but as you deploy apps to your foundation it will start to be populated. It is controlled by `cf-for-k8s` internals, and you won't need it for scaling.

Here's some sample output:

```bash
$ kubectl get pods -A | grep -v -e kube-system -e cf-workloads
NAMESPACE              NAME                                                            READY   STATUS      RESTARTS   AGE
cf-blobstore           cf-blobstore-minio-7c6698f96c-b9r6l                             2/2     Running     0          5d2h
cf-db                  cf-db-postgresql-0                                              2/2     Running     0          5d2h
cf-system              ccdb-migrate-scvwb                                              0/2     Completed   0          3d23h
cf-system              cf-api-clock-79cb6cb65-kcbhh                                    2/2     Running     0          3d23h
cf-system              cf-api-controllers-556f9954bd-ms9jb                             2/2     Running     0          5d2h
cf-system              cf-api-deployment-updater-7f947bd79d-45zjd                      2/2     Running     0          3d23h
cf-system              cf-api-server-7468bc587-8fjk9                                   6/6     Running     0          3d23h
cf-system              cf-api-server-7468bc587-wdfrl                                   6/6     Running     0          3d23h
cf-system              cf-api-worker-58675cfbdf-xzc99                                  3/3     Running     0          3d23h
cf-system              eirini-68584bc66d-b8sbn                                         2/2     Running     0          4d4h
cf-system              eirini-controller-775dc47668-wwv7x                              2/2     Running     0          4d4h
cf-system              eirini-events-657c494f44-vlzt8                                  2/2     Running     0          4d4h
cf-system              eirini-task-reporter-5695867b7b-79jtw                           2/2     Running     0          4d4h
cf-system              fluentd-4xbfx                                                   2/2     Running     0          5d2h
cf-system              fluentd-fpvjs                                                   2/2     Running     0          5d2h
cf-system              fluentd-jr7x5                                                   2/2     Running     0          5d2h
cf-system              fluentd-tg6vz                                                   2/2     Running     0          5d2h
cf-system              fluentd-ww4zx                                                   2/2     Running     0          5d2h
cf-system              instance-index-env-injector-844b6ffb7c-ckvxf                    1/1     Running     0          4d4h
cf-system              log-cache-5bdd8b49d-dw5hn                                       5/5     Running     0          5d2h
cf-system              metric-proxy-684856cbb6-jn5fx                                   2/2     Running     0          5d2h
cf-system              routecontroller-5b6c75d84-6dqjk                                 2/2     Running     0          5d2h
cf-system              uaa-7c7f984c96-l7w5g                                            3/3     Running     0          5d2h
istio-system           istio-ingressgateway-6w54n                                      2/2     Running     0          3d23h
istio-system           istio-ingressgateway-7s9sp                                      2/2     Running     0          3d23h
istio-system           istio-ingressgateway-gjtrq                                      2/2     Running     0          3d23h
istio-system           istio-ingressgateway-l2mfh                                      2/2     Running     0          3d23h
istio-system           istio-ingressgateway-rs6zr                                      2/2     Running     0          3d23h
istio-system           istiod-6c5f95b77f-pl7vm                                         1/1     Running     0          3d23h
kpack                  kpack-controller-6f4b4799cd-svsq2                               2/2     Running     0          5d2h
kpack                  kpack-webhook-59c6d6b695-xrnw2                                  2/2     Running     0          5d2h
```

There are many directions you can go with this information.

First, you can find out which containers are being run under a particular pod using the `kubectl` and `jq` commands (of course there are many alternatives). For example, to find the containers that are running on a `log-cache` pod, we could run this command:

```bash
$ kubectl get pod -n cf-system              log-cache-5bdd8b49d-dw5hn  -o json | jq '.spec.containers[] | [.name, .image]'
[
  "istio-proxy",
  "gcr.io/cf-routing/proxyv2:1.7.1"
]
[
  "cf-auth-proxy",
  "logcache/log-cache-cf-auth-proxy@sha256:b295d8b44104ecf0490881beef524479abfc410ece5d5a101f727a78f6e1ff36"
]
[
  "syslog-server",
  "logcache/syslog-server@sha256:1088dd665692f463b2fe8f9317c76853ddaf013c722c3d45dbcac95619b4bc47"
]
[
  "log-cache",
  "logcache/log-cache@sha256:081a57ec8127372ca643f12d375cbaeeb720cf7dc35413755620d814b09053a2"
]
[
  "gateway",
  "logcache/log-cache-gateway@sha256:aed9459d111ad16cad595682ba3408265eac5c331268500f2b59cb516e5d8056"
]
```

You can browse the kubernetes specs under config to determine how to scale other pods, given the above sample for the api-server as a template.

## Troubleshooting

`ytt` *will* give error messages if it finds a problem in some code. If there is no problem, it will emit over 16,000 lines of YAML. Normally, when you run `ytt` you should direct its output to a file, as we've done in the above examples. If there's an error, the message will be written to `stderr` and not to the redirected file. For example, let's rerun the vertical scaling example with one small change in the overlay code, saved in a file called `vertically-scale-api-server-missing-list-hyphen.yml` :


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



