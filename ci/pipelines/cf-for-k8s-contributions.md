# cf-for-k8s-contributions

## Purpose

This pipeline validates new releases of components integrated in cf-for-k8s and automatically pushes those releases to the `develop` branch of cf-for-k8s. Additionally, this pipeline validates pull requests to the repository that must succeed before merging.

## Groups

A separate group exists for each component that requires automated updates in cf-for-k8s and the default `all-autobumps` group aggregates them all. Separately, there is a group for validation of github pull requests.

* `all-autobumps`: all jobs that test each component to the develop branch of cf-for-k8s
  and merge them to main. Specific component groups listed below.
  * `buildpacks`: jobs to update the default standard language family paketo buildpacks based on new `latest` images on the paketo-buildpacks repos in the gcr.io registry.
  * `stack`: jobs to update the default stack used in cf-for-k8s with paketo buildpacks based on new images with the `full-cnb` tag in the `paketobuildpacks/run` and `paketobuildpacks/build` Dockerhub repos.
  * `capi-k8s-release`: jobs to update [capi-k8s-release](https://github.com/cloudfoundry/capi-k8s-release).
  * `cf-k8s-logging`: jobs to update [cf-k8s-logging](https://github.com/cloudfoundry/cf-k8s-logging).
  * `cf-k8s-networking`: jobs to update [cf-k8s-networking](https://github.com/cloudfoundry/cf-k8s-networking).
  * `eirini-release`: jobs to update [eirini-release](https://github.com/cloudfoundry-incubator/eirini-release).
  * `kpack`: jobs to update [kpack](https://github.com/pivotal/kpack/).
  * `metric-proxy`: jobs to update [metric-proxy](https://github.com/cloudfoundry/metric-proxy).
  * `uaa`: jobs to update [uaa](https://github.com/cloudfoundry/uaa) (and potentially [uaa-k8s-release](https://github.com/cloudfoundry/uaa-k8s-release) in the near future).
* `pr-validation`: jobs used to test pull requests against the repository.

## Validation Strategy

### Unit Testing and Vendir Sync Validation

We block acceptance testing on unit testing. Ginkgo unit test suites validate the main conditional branches in the ytt rendering logic with the help of the [yttk8smatchers](https://github.com/cloudfoundry/yttk8smatchers) library. We maintain the declarative state of dependencies managed by `vendir` by only updating the release reference before running `vendir sync` (and the `build.sh` script for components included in the `build/` directory).

### Acceptance Testing

Once unit testing is complete, we validate a fresh install on [KinD](https://github.com/kubernetes-sigs/kind) with the first and last kubernetes versions in the kubernetes version window declared in `supported_k8s_versions.yml` and an upgrade install on a [GKE](https://cloud.google.com/kubernetes-engine) cluster using the [rapid release channel](https://cloud.google.com/kubernetes-engine/docs/concepts/release-channels). Each of these runs smoke tests. Additionally the upgrade test uses [uptimer](https://github.com/cloudfoundry/uptimer) to measure availability during the upgrade process.

### PR Validation

PR validation matches the matrix tested in the `cf-for-k8s-main` pipeline. Note that a failed concourse job in the `pr-validation` group does not necessarily indicate action is required by pipeline maintainers. The failure is required to block acceptance testing on unit testing using a concourse passed constraint.

## Pipeline Management

This pipeline is managed via the `ci/templates/cf-for-k8s-contributions.yml` [ytt](https://github.com/vmware-tanzu/carvel-ytt) template. To make changes to the pipeline, update the template file (and its input values file `ci/inputs/cf-for-k8s-contributions.yml`), then run the `ci/configure` script to render the template with ytt and apply the changes with the [fly cli](https://concourse-ci.org/fly.html).

### Integrating a new component

To integrate a new component, update `ci/inputs/cf-for-k8s-contributions.yml` with a new element in the `releases` array:

```
releases:

...

- name: <new component>
  github_release: <true/false> (depending on whether the repo uses releases and provides them in a format recognized by vendir)
  github_branch: <main>
  github_uri: git@github.com:<my-org/new-component>
  vendir_github_release: <true/false> (depending on whether the repo uses releases and provides them in a format recognized by vendir)
  build_dir: "" (directory for components that have a script for transforming their release into generic yaml documents/templates)
```
