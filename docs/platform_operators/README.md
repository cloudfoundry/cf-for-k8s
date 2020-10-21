# Platform Operator Docs

- Setup (Day 1 Concerns)
  - [Configuration Values/Parameters](config-values.md)
  - [Configuring External Databases](external-databases.md)
  - [Configuring an External Blobstore](external-blobstore.md)
  - [Using a Dedicated Registry for System Images](system-registry-management.md)
  - [Setup Ingress Certs with Let's Encrypt](setup-ingress-certs-with-letsencrypt.md)
  - [Setup a Loadbalancer Static IP](setup-static-loadbalancer-ip.md)
- Maintenance (Day 2 Concerns)
  - [Rotating Secrets and Certs](rotating-secrets-and-certs.md)
  - [Scaling the Platform](scaling.md)
- [Networking Docs](networking)
  - [Networking Metrics and Monitoring](networking/networking-metrics-and-monitoring.md)
  - [Ingress Routing Topology](networking/ingress-routing-topology.md)
  - [Gateway Access Logs](networking/gateway-access-logs.md)
  - [Sidecar Access Logs](networking/sidecar-access-logs.md)

## A Word of Caution for Operators Regarding `kubectl`

Operators are welcome to "peek into the system" using `kubectl`. However, direct modification on cluster resources can lead to unexpected consequences. Many controllers have not yet built in any tolerance for direct user interaction with internal components, such as Istio and Fluentd. At the moment, some of our controllers don't actively reconcile: if someone modifies a resource belonging to CloudFoundry using `kubectl`, it could introduce conflicting configurations that CF is not able to handle. For example, if you modify a Route Custom Resource's hostname, the change will not be reflected when using the `cf` CLI.

