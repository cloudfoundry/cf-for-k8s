# build-component-images

## Purpose
This pipeline builds images that have not yet been moved to their own `cf-for-k8s-<component>-images` pipeline.

## Groups
- `all`: the default group that aggregates all the image build groups. With the completion of image build standardization this may again become the source of other image builds.
- `statsd-exporter`: currently this is the only component image we build in the pipeline.

## Image building
This pipeline builds using the concourse [oci-build-task](https://github.com/vito/oci-build-task).

The build image jobs also adds annotations to the images using [deplab](https://github.com/vmware-tanzu/dependency-labeler).

## Pipeline management

This pipeline is managed via the `ci/templates/build-component-images.yml` [ytt](https://github.com/vmware-tanzu/carvel-ytt) template. To make changes to the pipeline, update the template file (and its input values file `ci/inputs/build-component-images.yml`), then run the `ci/configure` script to render the template with ytt and apply the changes with the [fly cli](https://concourse-ci.org/fly.html).

### Adding a new component

To integrate a new component, update `ci/inputs/cf-for-k8s-contributions.yml` with a new element in the `releases` array:

```
components:

...

  - name: <component name>
    release:
      repository: <github release repo>
      owner: <github org of release repo>
    sources:
      - repository: <github source repo>
        owner: <github source repo org>
    images:
      - name: <image name>
        dockerfile:
          repository: <source repo from sources list>
          path: <path in source repo to Dockerfile>
        context:
          repository: <source repo from sources list>
          path: <path in source repo from which to run the docker build>
        params: {<custom params for docker build>}
```
