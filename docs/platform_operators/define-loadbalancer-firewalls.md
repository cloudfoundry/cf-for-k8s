# Configure Cloud Provider's Firewalls for Istio Loadbalancer

## Objective

At end of this setup, you will be able to install cf-for-k8s with a loadbalancer that is only accessible to clients with the specific IP addresses.

## Prerequisites

- Cluster should support `LoadBalancer` services.

## Steps to setup cloud provider firewalls

The following instructions assume you have created `cf-install-values.yml`.

1. Add `istio_source_ranges` key and the IP ranges that are allowed to access the load balancer to your `cf-install-values.yml`

    > Note that the append annotation must be applied to each item you want to insert.

    ```yaml
    istio_source_ranges:
    #@overlay/append
    - "130.211.204.1/32"
    #@overlay/append
    - "130.211.204.2/32"
    ```

1. Follow the instructions from [deploy doc](../deploy.md) to generate the final deploy yml using `ytt` and then `kapp` deploy cf-for-k8s to your cluster.

## Verify the cloud provider firewalls configuration

1. Lookup the Loadbalancer firewall configuration. It should match the IP ranges you used above.

    ```console
    $ aws ec2 describe-security-groups --group-ids sg-06a0361d9ad14535f --output yaml
    SecurityGroups:
    - Description: Security group for Kubernetes ELB a73958422feb34578a87bc2185e739c8
        (istio-system/istio-ingressgateway)
      GroupId: sg-06a0361d9ad14535f
      GroupName: k8s-elb-a73958422feb34578a87bc2185e739c8
      IpPermissions:
      - FromPort: 80
        IpProtocol: tcp
        IpRanges:
        - CidrIp: 130.211.204.1/32
        - CidrIp: 130.211.204.2/32
        Ipv6Ranges: []
        PrefixListIds: []
        ToPort: 80
        UserIdGroupPairs: []
    ...
    ```
