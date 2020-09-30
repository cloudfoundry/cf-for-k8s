# Setup a static IP for loadbalancer

## Objective

Currently, the cluster issues a dynamic loadbalancer IP on a new cf-for-k8s install. The operator is required to update the DNS entry before she can perform any cf operations.

At end of this setup, you will be able to install cf-for-k8s with a static IP. You can then reinstall cf-for-k8s any number of times without needing to update DNS entries on every install.

## Prerequisites

- In addition to `LoadBalancer` services support, your kubernetes cluster should support setting static IP to `LoadBalancer`.
- A reserved IP address (IPv4?).
- A DNS a record with your reserved IP pointing to your desired system and app Domains. This is a one time setup for your foundation e.g.

      ```console
      # sample A record in Google cloud DNS. The IP address below is the reserved IP from your cloud provider
      Domain         Record Type  TTL  IP Address
      *.<cf-domain>  A            30   <reserved ip address>
      ```

## Steps to setup static IP

The following instructions assume you have created `cf-install-values.yml`. You have the option of doing this before you install cf-for-k8s or after you installed cf-for-k8s on a cluster.

1. Add `load_balancer.static_ip` key and the reserved IP to your `cf-install-values.yml`

    ```yaml
    load_balancer:
      enable: true
      static_ip: "<reserved ip address>"
    ```

1. Follow the instructions from deploy doc to generate the final deploy yml using `ytt` and then `kapp` deploy cf-for-k8s to your cluster.

## Verify the static IP setup

1. Lookup the ingress gateway external IP address. It should match the IP address you used above. Please note that it may take several minutes for the reserved IP to be reflected in your cluster.

    ```console
    $ kubectl get svc -n istio-system istio-ingressgateway
    NAME                   TYPE           CLUSTER-IP   EXTERNAL-IP                  PORT(S)  AGE
    istio-ingressgateway   LoadBalancer   10.0.10.32   <your reserved ip address>   ...      22m
    ```

1. Verify the IP is reachable via `dig` command

    ```console
    $ dig api.<cf-domain>
    ...
    ;; ANSWER SECTION:
    api.<cf-domain>. 5	IN	A	<your reserved ip address>
    ```

1. Follow the steps in the main deploy doc under section Validate the deployment to verify you're able to target CF CLI and push apps to the foundation.

1. You can delete cf-for-k8s from the cluster by running `kapp delete -a cf` and the reinstall the cluster with the same `cf-install-values.yml`. This time the loadbalancer will use the reserved IP instead of generating a dynamic IP. You can verify by targing CF CLI to `api.<cf-domain>` and cf push app to the foundation.
