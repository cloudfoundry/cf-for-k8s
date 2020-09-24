# Scaling Networking

## Local Development
If you would like cf-for-k8s to be right-sized for local development on a laptop, 
you can ignore this page and follow the regular deployment docs as by default
cf-for-k8s is configured for a small footprint deployment. This documentation
describes how to scale the cf-for-k8s networking components for production use cases.

## Larger Scale Deployments
If you would like to scale up the networking components for a larger scale
environment, simply:
1. Copy the following example into a `scaling-networking.yml` file
1. Adjust the values to your liking
1. Append `-f scaling-networking.yml` to the ytt command you run for deployment

```
#@ load("@ytt:overlay", "overlay")
#@ load("@ytt:json", "json")

#! Modify these values to adjust scaling characteristics

#@ ingress_replicas = 2
#@ ingress_cpu_request = "1"
#@ ingress_cpu_limit = "2"
#@ ingress_mem_request = "1Gi"
#@ ingress_mem_limit = "2Gi"

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

#! DO NOT MODIFY BELOW THIS LINE

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
  replicas: #@ ingress_replicas
  template:
    spec:
      containers:
      #@overlay/match by="name", expects=1
      - name: istio-proxy
        #@overlay/match missing_ok=True
        resources:
          limits:
            cpu: #@ ingress_cpu_limit
            memory: #@ ingress_mem_limit
          requests:
            cpu: #@ ingress_cpu_request
            memory: #@ ingress_mem_request

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
