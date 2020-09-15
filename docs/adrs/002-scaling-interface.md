# Scaling Interface

## The Problem

For various reasons we often need to expose underlying k8s properties to the operator (Rachel).  Scaling properties are one good example where we would need to expose a very large set of properties modeling every pod and every container’s, replica and resource specs.

What is the best approach for achieving this?

## The Alternatives

### Alternative #1 - Define configuration properties

Under this alternative we would provide a large set of scale properties that can be used to configure the scale characteristics of a deployment.

E.g. for every pod and container we would expose a property interface like this:

```
capi:                   <-- component 
  cf-api-server:        <-- pod 
    replicas: X         <-- default replica value
    cf-api-server:      <-- container
      resources
        requests:    
          mem: X        <-- default mem value
          cpu: X        <-- default cpu value
        limits: 
          mem: X
          cpu: X
```

These values would simply be mapped down to the underlying component’s k8s yaml.  Hence why we later describe this as API mirroring. 

#### Pros
- Simple for the operator, they simply have to provide values in their cf-values.yml input file
- Shields the operator from the K8s API
- Shields them from needing to write overlays

#### Cons
- It is not clear that we have received any feedback that this is the interface that operators actually want 
- Mirror API predicament.  For use cases such as this (scaling) where there are a lot of repeated properties and because this is un-opinionated this often ends being a mirror of the underlying API
    - Where do you stop?  Some operators will want more, some operators will want less.
    - Always playing catchup to the K8s API
- Once these properties are out there as part of our configuration interface we have to support them forever
- Ties the cf-for-k8s as a product to the k8s API

### Alternative #2 - K8s yaml as an API

Under this alternative we would do nothing to expose specific K8s properties and instead publicize that the operator can implement their own overlays. 

#### Pros
- No additional scaling properties needed 
- Prevents the mirror API problem
- Open; allows the operator to overlay anything.  If it is K8s API, it can be overlayed
    - Possibly better for an open source product that is trying to be as widely applicable as possible
- Uses the YTT toolchain in the way it is recommended to be used
- Forward compatible;  as K8s API changes cf-for-k8s doesn’t have to expose more and more properties
- Still allows us to offer properties in future (after receiving feedback) but those properties can be more opinionated in order to prevent the mirror API problem

#### Cons
- Significantly more work/complicated for the operator who now has to know how to create ytt overlays
    - This can be mitigated with docs and with better ytt error reporting (which they are working on)  
    - Overlays written by operators are generally simpler than the generic ones we need to write as authors of cf-for-k8s
- Operator is not shielded from changes to the k8s api.  When K8s changes its API it may break operator’s overlays
    - As k8s matures this will become less of an issue
- Doesn’t provide any support for scaling to downstream vendors 

### Alternative #3 - Scaled, or not

Under this alternative we would provide a scale property allowing cf-for-k8s to either be scaled, or not.

When false (or None?) cf-for-k8s deploys with replicas: 1 and small requests/limits.  When true (or small?|scaled?) cf-for-k8s deploys with replicas: >= 2 and larger requests/limits sufficient to satisfy our first stage scale requirements of 100 AIs

This would require a couple of scaling overlays in cf-for-k8s config/.

#### Pros
- Simple for the operator, they simply have to provide a value in their cf-values file to obtain a cf-for-k8s deployment that is scaled
- Shields the operator from the K8s API and overlays until they want to run cf-for-k8s at large scale in which case presumably they should be familiar enough with k8s to allow them to run a large-scale deployments and by implication to write ytt overlays
- This avoids the mirror API problem as we are adopting a very opinionated configuration interface
- Uses the YTT toolchain in the way it is recommended to be used
- Forward compatible;  as K8s API changes cf-for-k8s doesn’t have to expose more and more properties
- Provide one, probably two scaling overlays that vendors can piggyback on 

#### Cons
- Do we really know what scale: true means?
    - Presumably it means HA but we haven’t yet tested/achieved uptime of the control plane, just apps atm.  Should a deployment be scaled to replicas:2?  Or replicas:3?  Does this also require an HA k8s cluster?
        - We should work with community members to determine appropriate values to satisfy first stage scale requirements
- We will have to test both of these configurations to some degree
    - But that could just be overlays "unit tests", at least initially

### Alternative #4 - T-shirt sizes

Under this alternative we would provide scale properties: none, small and large.

“None” would be in support of the developer edition and would deploy cf-for-k8s with replicas: 1 and small request/limits accordingly .  When small or large is chosen we would deploy a cf-for-k8s with increasing large replica and resource settings.

#### Pros
- Simple for the operator, they simply have to provide a value in their cf values file to obtain a cf-for-k8s deployment that is scaled to some level
- Shields the operator from the K8s API and overlays until they want to run cf-for-k8s at large scale in which case presumably they should be familiar enough with k8s to allow them to run large-scale deployments and by implication to write ytt overlays
- This avoids the mirror API problem as we are adopting an opinionated configuration interface
- Uses the YTT toolchain in the way it is recommended to be used
- Forward compatible;  as K8s API changes cf-for-k8s doesn’t have to expose more and more properties
- Provide one, probably two scaling overlays that vendors can piggyback on 

#### Cons
- How do we determine what the scaled options are?
    - We should work with community members to determine appropriate values for each option that satisfy our first and second stage scale requirements
- We will have to test all of these configurations to some degree
    - But that could just be overlays "unit tests", at least initially

## Unknowns

## Conclusions
There is a strong desire to simply not mirror the k8s API through the cf-for-k8s config interface as this is basically what an YTT overlay are for.  We know from experience
that this approach is problematic over time.  This rules of Alternative #1.  At the same time there is a strong desire to not expose users to overlays either, 
unless absolutely necessary.  This rules out Alternative #2.

We therefore believe Alternative #3 or #4 is the best alternative for us for 1.0 release.  Most of the time the operator is protected from having to write overlays.
At the same time they provide a scaling overlay for downstream vendors to base their scaling interfaces on.   We prefer #3 over #4 as our intention, for 1.0, is to
support kick-the-tyres and small production deployments only. 
