# Maintaining cf-for-k8s

This document is intended for cf-for-k8s maintainers.

## Dependencies

see "Dependencies" in [community/PREPARING-FOR-DEVELOPMENT.md](/community/PREPARING-FOR-DEVELOPMENT.md#dependencies).

## Smoke tests

see "Running Smoke Tests" in [community/PREPARING-FOR-DEVELOPMENT.md](/community/PREPARING-FOR-DEVELOPMENT.md#running-smoke-tests).

## Directory structure

- `config/` includes all necessary configuration for CF
  - `_ytt_lib/` includes unmodified configuration fetched from components' repos (controlled via `/vendir.yml`)
  - `values.yml` specifies all possible data values used
  - `*.yml` includes configuration to glue components together
- `build/` includes building instructions for components that do not provide plain YAML or ytt templates
  - this directory is only used by cf-for-k8s maintainers
  - `build.sh` in each sub-directory has specific build instructions

## Image References

Image references are expected to use an image SHA digest. If using [kbld](https://get-kbld.io/) to build images as suggested in the component development flow, the image reference should include the digest by default.

## Tips

- `alias k=kubectl`
  - useful alias
- `kubectl get pod -A -o custom-columns='NAME:metadata.name,INITCONS:spec.initContainers[*].image,CONS:spec.containers[*].image'`
  - show all used images in pods
