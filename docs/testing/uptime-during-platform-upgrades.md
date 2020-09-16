### Application availability during an upgrade

CF-K8s currently supports 95% app uptime during an upgrade.
For example, given a deployment of cf-k8s with an upgrade duration of 3min, we expect 9 seconds app downtime during the upgrade. 

The number of gateways required for a deployment of cf-k8s is proportional to the the load profile of applications deployed on the platform. 
Based on the Istio team's testing, in an unknown test environment, a single Envoy consumes 0.5 vCPU and 50 MB memory per 1000 requests per second.
Users might observe different resource consumption by their gateways based on their environment. 

In our testing we observed that adding 1 additional gateway increases the upgrade duration by 30 seconds. 
