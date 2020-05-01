#!/bin/sh

echo "WARNING: The hack scripts are intended for development of cf-for-k8s. 
They are not officially supported product bits.  Their interface and behavior
may change at any time without notice." 1>&2

for pod in $(kubectl get pod -l security.istio.io/tlsMode=istio -n cf-system -o jsonpath='{.items..metadata.name}') ; do
  echo $pod
  for service in $(kubectl get services -n cf-system | awk '/^[a-z]/ { print $1 }') ; do
    istioctl authn tls-check ${pod}.cf-system ${service}.cf-system.svc.cluster.local
    echo 
  done
  echo
done
