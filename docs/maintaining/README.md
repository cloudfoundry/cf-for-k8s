# Maintaining cf-for-k8s

This document is intended for cf-for-k8s maintainers.

## Playbooks

* [Accepting Breaking Changes](playbook-accepting-breaking-changes.md)
* [Updating Supported Kubernetes Versions](playbook-updating-supported-kubernetes-version.md)


## Dependencies

see "Dependencies" in [community/PREPARING-FOR-DEVELOPMENT.md](/community/PREPARING-FOR-DEVELOPMENT.md#dependencies).

## Smoke tests

see "Running Smoke Tests" in [community/PREPARING-FOR-DEVELOPMENT.md](/community/PREPARING-FOR-DEVELOPMENT.md#running-smoke-tests).

## Directory structure

- `config/` includes all necessary configuration for CF
  - `<component>/*.yml` cf-for-k8s specific configuration of component
  - `<component>/_ytt_lib/` unmodified configuration fetched from components' repos (controlled via `/vendir.yml`)
  - `values/00-values.yml` specifies all possible data values used
  - `*.yml` configuration that glue components together
- `build/` includes building instructions for components that do not provide plain YAML or ytt templates
  - this directory is only used by cf-for-k8s maintainers
  - `<component>/build.sh` in each sub-directory has specific build instructions
    - These `build.sh` scripts take no arguments and can be run from any directory
    - Each `build.sh` also runs `kbld`, which verifies that every image reference includes its digest
  - `<component>/_vendir` contains the unmodified configuration fetched from the component's repo (controlled via `/vendir.yml`)
    - The structure under each component varies depending on the component's own helm chart
  - Every `<component>/` directory contains a `values` file used to configure `helm`; sometimes it's called `values.yml`, but the name is always used explicitly in `build.sh`
  - All the components use `helm` to generate yaml manifests except `istio`, which is using its own [`istioctl manifest generate`](https://istio.io/v1.7/docs/reference/commands/istioctl/#istioctl-manifest-generate) command

## Image References

Image references are expected to use an image SHA digest. If using [kbld](https://get-kbld.io/) to build images as suggested in the component development flow, the image reference should include the digest by default.

## Update Example

Suppose we want to update `eirini` from version `A` to `B`.

1. First update the tag field in `vendir.yml` under `path: build/eirini/_vendir`.  It should currently be set to whatever the value of `A` is; change this to `B` and save the file.

1. Run `vendir sync`. This should update the contents of the `_vendir` subdirectory of `build/eirini`

1. Change to `build/eirini`

1. Review local changes by running `git diff _vendir/eirini/`

1. Run `./build.sh`

1. Change back to the main directory (`cd ../../`), `kapp deploy` the new version of eirini, and if everything's good you can commit the local changes.

### Pipeline Updates

The pipeline code in `ci/tasks/bump-core-component/task.sh` does the above generically:

1. It sets the tag to either the explicit release tag (e.g. `v1.9.0`) or a git commit SHA

1. It updates the tag field in `vendir.yml`

1. It runs `vendir sync`

1. It runs `build.sh` if it exists

1. It finally does a `git commit` to bump the new version

## Tips

- `alias k=kubectl`
  - useful alias
- `kubectl get pod -A -o custom-columns='NAME:metadata.name,INITCONS:spec.initContainers[*].image,CONS:spec.containers[*].image'`
  - show all used images in pods
