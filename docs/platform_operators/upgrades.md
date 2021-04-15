# Upgrading CF

## Table of Contents
- [Overview](#overview)
  * [Performing the Upgrade](#performing-the-upgrade)
    + [Updating Values](#updating-values)
    + [Deploying CF](#deploying-cf)
- [Rotating Secrets and Certs](#rotating-secrets-and-certs)
- [Networking Considerations](#networking-considerations)
  * [Upgrading Istio](#upgrading-istio)
  * [DNS Considerations](#dns-considerations)
- [Platform Availability](#platform-availability)
- [Rolling Back](#rolling-back)

## Overview
CF for Kubernetes uses [`kapp`](https://github.com/vmware-tanzu/carvel-kapp) to manage its lifecycle. When upgrading, `kapp` will diff the changes you are applying with the deployed CF on the cluster. It will then show you a list of changes it plans to make on the cluster. `kapp` will not exit until all changes are applied and the updated resources are running.

### Performing the Upgrade

#### Updating Values
Read the cf-for-k8s release notes (specifically the `Notices`) to determine if there are any new data values required by the new cf-for-k8s release. If there are, add them to the values file you used in the previous deploy.

#### Deploying CF
1. Render the new K8s template to raw K8s configuration

    ```console
    ytt -f config -f /path/to/updated-cf-values.yml > ${TMP_DIR}/cf-for-k8s-rendered.yml
    ```
 
1. Install CF using `kapp` and pass the above K8s configuration file. Carefully look over the `kapp` output to make sure nothing is changing unexpectedly (for example secrets are unlikely to change unless explicitly rotated).

    ```console
    kapp deploy -a cf -f ${TMP_DIR}/cf-for-k8s-rendered.yml
    ```

1. Save the updated values file somewhere secure (remember, it contains secrets!) for future upgrades. You also may want to consider saving the final rendered K8s configuration file for future reference.

1. Validate your apps continue to exist and are routable. You may also consider pushing a new app to validate the CF control plane.

## Rotating Secrets and Certs
It's possible to update most secrets and certs as part of the upgrade. See the [Rotating Secrets and Certs docs](rotating-secrets-and-certs.md) for more details.

## Networking Considerations

### Upgrading Istio
Some releases of cf-for-k8s may include Istio upgrades (refer to the release notes to see if this is the case). Istio does not support jump upgrades across multiple minor versions, so it is important to keep this in mind when upgrading cf-for-k8s.

For example, consider the following scenario:

* cf-for-k8s version _x_ includes Istio 1.7
* cf-for-k8s version _y_ includes Istio 1.8
* cf-for-k8s version _z_ includes Istio 1.9

If you are currently on cf-for-k8s version _x_ **you must** first upgrade to version _y_ before upgrading to version _z_ to upgrade Istio successfully with minimal downtime.

### DNS Considerations
If you did not explicitly specify an external IP for the `istio-ingressgateway` `LoadBalancer` service to use via [these instructions](setup-static-loadbalancer-ip.md), 
you should double check that you update the DNS records for your foundation's app and system domains appropriately as outlined [here](../deploy.md#steps-to-deploy).

## Platform Availability
See the [platform availability docs](../platform-availability.md) for more info.

## Rolling Back
The CF API (Cloud Controller) does not support rollbacks after its database has been migrated. As a consequence, cf-for-k8s does not support rolling back versions and we strongly advise that you do not attempt to.
