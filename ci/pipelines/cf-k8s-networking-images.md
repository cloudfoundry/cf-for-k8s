# cf-k8s-networking-images

## Purpose
This pipeline builds some of the images used by cf-for-k8s networking and the images used in the validation of networking in cf-for-k8s. Once built, the images are pushed to repositories in the cloudfoundry Dockerhub organization.

## build-and-annotate-fluent-bit-image
Builds the Docker image for the fluentbit sidecar that we colocate with the Istio Ingressgateway Pods. This sidecar is responsible for getting access logs for apps into the logging system. It automatically commits an image bump to the `develop` branch of cf-for-k8s which is tested by CI.

Disclaimer: This does not actually annotate the image.

## build-upgrade-sidecars-job-image
Builds the Docker image for the upgrade-sidecars Job that we run after upgrading Istio. This Job is responsible for rolling out apps and system components so that they have an up to date sidecar proxy. It automatically commits an image bump to the `develop` branch of cf-for-k8s which is tested by CI.

## build-httpbin-image
This builds a modified version of the [httpbin](https://httpbin.org) app that the networking acceptance tests use internally for testing.

## build-proxy-image
This builds the [CF "proxy" app](https://github.com/cf-routing/proxy) that the networking acceptance tests use internally for testing Pod to Pod connectivity.
