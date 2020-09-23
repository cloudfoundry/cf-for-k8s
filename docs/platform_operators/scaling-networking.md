# Scaling cf-for-k8s Networking Components

## If you want to scale cf-for-k8s networking components for deployment on a laptop:

cf-for-k8s is already scaled for developer laptops by default.

## If you want to scale cf-for-k8s networking components for larger scale deployments:

You will need to edit some config files inside cf-for-k8s and run some scripts
to regenerate other manifest files.

Before using these instructions, you will need to determine your desired values for:
* Number of ingressgateway and istiod pods
* Resource requests and limits for ingressgateway, istiod, and routecontroller pods

TODO: sidecar resource requests/limits can be controlled via annotations on the pods.

Prereqs: istioctl at the proper version (TODO: how do I tell which version?)

Now that you know what values you want istio deployed with, we'll create and
delete some config files in cf-for-k8s to achieve those values.

1. Remove the following:
  * build/istio/overlays/ingressgateway-daemonset.yaml (removing this keeps
    ingressgateways as deployments)
  * config/istio/remove-hpas-and-scale-istiod.yml (removing this makes istiod
    have more than 1 replica)

1. In order to configure the ingressgateways and istiod, you will make a new
overlay file in `build/istio/`.
  * This example configures the ingressgateway and istiod replicas to 2 (so
    that they are distinguishable from the default of 1)
  * It also configures the resource requests and limits on ingressgateways and istiod.
  * If you do not want to set non-default settings for one of these values, you
    can simply not include that section of the example.
```
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "IstioOperator"}),expects=1
---
spec:
  components:
    ingressGateways:
    #@overlay/match by="name", expects=1
    - name: istio-ingressgateway
      k8s:
        #@overlay/match expects=0
        overlays:
        - kind: Deployment
          name: istio-ingressgateway
          patches:
          - path: spec.replicas
            value: 2
        #@overlay/replace
        hpaSpec:
          minReplicas: 2
          maxReplicas: 2
        service:
          #@overlay/match missing_ok=True
          type: LoadBalancer
        #@overlay/match missing_ok=True
        resources:
          limits:
            cpu: "2"
            memory: 2Gi
          requests:
            cpu: "1"
            memory: 1Gi
    pilot:
      k8s:
        #@overlay/match missing_ok=True
        replicaCount: 2
        #@overlay/match expects=0
        overlays:
        - kind: Deployment
          name: istiod
          patches:
          - path: spec.replicas
            value: 2
        #@overlay/replace
        hpaSpec:
          minReplicas: 2
          maxReplicas: 2
        #@overlay/match missing_ok=True
        resources:
          limits:
            cpu: "2"
            memory: 2Gi
          requests:
            cpu: "1"
            memory: 1Gi
```

1. In order to configure routecontroller, you will need to make a separate
overlay in `config/networking/`.
  * This example sets the resource requests and limits for routecontroller to
    non-default values.
  * If you do not want to configure non-default values for routecontroller
    resources, you can skip this step.
```
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({"kind": "Deployment", "metadata": { "name": "routecontroller"}}),expects=1
---
spec:
  template:
    spec:
      containers:
      #@overlay/match by="name", expects=1
      - name: routecontroller
        #@overlay/match missing_ok=True
        resources:
          limits:
            cpu: 400m
            memory: 20Gi
          requests:
            cpu: 200m
            memory: 30Mi
```

Now that all the configuration files have been modified, it's time to use that
configuration to generate the manifest files to deploy. These commands assume
you are in `cf-for-k8s/build/istio`.

1. In order to apply the ops file to edit the istioctl-values.yaml:
  `ytt -f istioctl-values.yaml -f istioctl-overlay.yaml > istioctl-values.yaml`
  * Note: this overwrites the existing istioctl-values.yml file. You may
    choose the back the file up under a different name before running this
    command, or if your copy of cf-for-k8s is a git repo, you can use git
    commands to get back to the prior state as desired.
1. In order to generate the modified istio manifest, run: `./build.sh`

Now that you've edited your istio config, you can continue following the normal
deploy steps. The modifications to the routecontroller config will be applied
during this process. Here is a brief summary of the standard deploy process:
1. Generate your cf-values: `./hack/generate-values.sh -d your.domain > /your/cf-values.yml`
1. Create your rendered values: `ytt -f config -f /your/cf-values.yml > /your/rendered-cf-values.yml`
1. Deploy your cf: `kapp deploy -a cf -f /your/rendered-cf-values.yml`

