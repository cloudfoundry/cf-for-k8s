# build-statsd-exporter-image

## Purpose
This pipeline builds the statsd exporter image that is a dependency of multiple cf-for-k8s components: capi-k8s-release and uaa.

## Image building
This pipeline builds using the concourse [oci-build-task](https://github.com/vito/oci-build-task). We also use this task to annotate the image with OCI labels.

## Pipeline management

This pipeline is managed directly via the `ci/pipelines/build-statsd-exporter-image.yml` concourse pipeline template. To make changes to the pipeline, update the file directly, then run the `ci/configure` script to apply the changes with the [fly cli](https://concourse-ci.org/fly.html).
