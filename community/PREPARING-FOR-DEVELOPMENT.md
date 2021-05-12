# Developing CF Components

- [High-Level Flow](#high-level-flow)
  * [Step 1: Do local development](#step-1--do-local-development)
  * [Step 2: PR those changes into CF for K8s](#step-2--pr-those-changes-into-cf-for-k8s)
- [Dependencies](#dependencies)
  * [Templating and Deployment](#templating-and-deployment)
  * [Smoke Tests](#smoke-tests)
  * [Vendoring](#vendoring)
- [Running Smoke tests](#running-smoke-tests)
- [Suggested Component Directory Structure and Local Development Workflow](#suggested-component-directory-structure-and-local-development-workflow)
  * [Additional Dependencies](#additional-dependencies)
  * [Component Directory Structure](#component-directory-structure)
  * [Local Development Workflow](#local-development-workflow)
  * [Sample kbld config](#sample-kbld-config)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

## High-Level Flow

### Step 1: Do local development and make a component PR

In the component repo (e.g. `capi-k8s-release`, `uaa`, `cf-k8s-networking`, etc. ):
1. make changes and create a new Docker image
1. tell your local copy of `cf-for-k8s` to use that new image by updating the image reference
1. test that these changes integrate well (i.e. [deploy](https://cf-for-k8s.io/docs/deploying/) and [run smoke tests](#running-smoke-tests))
1. make a PR to the component repo following its contributions guidelines

_(See a suggested local development workflow, [below](#suggested-component-directory-structure-and-local-development-workflow))_

### Step 2: PR those changes into CF for K8s

Once the component PR has been merged, in `cf-for-k8s` repo:
1. checkout `develop` and create a new branch
    - If you do not have access to creating branches and believe you should, please inquire in the [#cf-for-k8s](https://cloudfoundry.slack.com/archives/CH9LF6V1P) slack channel
    - Otherwise please submit changes from a fork
1. If you are adding/updating data values (i.e. `config/values.yml`), please also add those changes to the `sample-cf-install-values.yml` file
1. tell `vendir` about the change by updating the `ref:` in `vendir.yml` to the new commit SHA
1. synchronize relevant files from the component repo by running `vendir sync`
1. commit these changes and push to the branch
1. [submit a PR to `cf-for-k8s`](https://github.com/cloudfoundry/cf-for-k8s/compare/develop...your-branch-name-here)
   - it should contain changes to `vendir.yml`, `vendir.lock.yml`, and the template config changes from `vendir sync`

## Dependencies

### Templating and Deployment
- [ytt](https://get-ytt.io/)
- [kapp](https://get-kapp.io/)

### Smoke Tests
- [ginkgo](https://github.com/onsi/ginkgo#set-me-up)

### Vendoring
- [vendir](https://github.com/k14s/vendir) v0.8.0+ (includes the `directory` flag, used in the development workflow)

## Running Smoke tests

1. [Deploy](https://cf-for-k8s.io/docs/deploying/) your instance of cf-for-k8s.
1. Configure the smoke test environment variables as suggested, below

   ```
   export SYSTEM_DOMAIN=<your system domain>
   export SMOKE_TEST_PASSWORD=<CF Admin password from `cf-values.yml`>
   ```
1. Run the smoke test suite

    ```
    cd tests/smoke
    export SMOKE_TEST_API_ENDPOINT=api.${SYSTEM_DOMAIN}
    export SMOKE_TEST_USERNAME=admin
    export SMOKE_TEST_APPS_DOMAIN=apps.${SYSTEM_DOMAIN}
    export SMOKE_TEST_SKIP_SSL=true
    ginkgo -v -r ./
    ```

## Suggested Component Directory Structure and Local Development Workflow

### Additional Dependencies

In addition to the dependencies above, the workflow below requires these:

- [kbld](https://get-kbld.io/)
- [minikube](https://github.com/kubernetes/minikube)

### Component Directory Structure
To simplify the component development workflow, we recommend repositories organize configuration thusly:

```
├── example-component
│   ├── config               - K8s resources
│   │   ├── deployment.yml
│   │   └── values
│   │       ├── _default.yml - contains schema/defaults for all values used within config
│   │       └── images.yml   - contains resolved image references (ideally in digest form)
│   └── build                - configuration for the build of CF-for-K8s
│       └── kbld.yml
```

Notes:
- place all K8s configuration under one directory. e.g. `config/` _(so that while invoking `ytt` you always specify just that one directory.)_
- within the `config/` directory, gather data value file(s) into a sub-directory: e.g. `config/values/` _(so that while invoking `vendir sync` you always specify just that one directory.)_
- place anything required to configure building/generating K8s resource templates or data files in a separate directory. e.g. `build` _(so that all that's in the `config` directory are only the K8s resources being contributed to CF-for-K8s)_

### Local Development Workflow

These instructions assume that you are using the directory structure, above.

1. Create or claim a Kubernetes cluster.  We expect these instructions to work for any distribution of Kubernetes, your mileage may vary (local or remote).
1. Checkout `cf-for-k8s` develop and install it to your cluster.
1. Start a local Docker Daemon so that you can build (and push) local Docker images.

   Here, we install `minikube` for its Docker Daemon (and not necessarily as our target cluster).
    ```
    minikube start
    eval $(minikube docker-env)
    docker login -u ...
    ```
1. Make changes to your component
1. Rebuild your component image and update any image references in your configuration.

   Here, we use `kbld` and generate a ytt data value file (i.e. `config/values/images.yml`) with that resolved image reference:
    ```
    cd ~/workspace/example-component
    cat <(echo "#@data/values"; kbld -f build/kbld.yml --images-annotation=false) \
        >config/values/images.yml
    ```
    _Note: `ytt` merges data files in alphabetical order of the full pathname.  So, `config/values/_default.yml` is used first, THEN `config/values/images.yml` (see [k14s/ytt/ytt-data-values](https://github.com/k14s/ytt/blob/master/docs/ytt-data-values.md#splitting-data-values-into-multiple-files)).  Therefore, it is critical that whatever name you choose for the generated data file (here, `images.yml`), it sorts _after_ `_default.yml`._

    _Note: see [Sample kbld config](#sample-kbld-config), below for an example of a `kbld` config._

1. Sync your local component configuration into the `cf-for-k8s` repo.

   Here, we use vendir's [`--directory`](https://github.com/k14s/vendir/blob/985506a54038f6e7871879d4fbee9df2b6cf8add/docs/README.md#sync-with-local-changes-override) feature to sync _just_ the directory containing our component:

    ```
    cd ~/workspace/cf-for-k8s
    vendir sync \
      --directory config/_ytt_lib/<path-to-component>=~/workspace/<path-to-component>
    ```

    For example, sync'ing _just_ CAPI would look like this:

    ```
    cd ~/workspace/cf-for-k8s
    vendir sync \
      --directory config/_ytt_lib/github.com/cloudfoundry/capi-k8s-release=~/workspace/capi-k8s-release/
    ```
1. Re-deploy `cf-for-k8s` with your updated component.


### Sample kbld config

See [kbld docs](https://carvel.dev/kbld/docs/latest/config/) to configure your own `kbld.yml`.

Assuming your `ytt` template takes the data value at `image.example` as the image reference...

```yaml
images:
  example: example-component-image
---
apiVersion: kbld.k14s.io/v1alpha1
kind: Sources
sources:
- image: example-component-image
  path: .
---
apiVersion: kbld.k14s.io/v1alpha1
kind: ImageDestinations
destinations:
- image: example-component-image
  newImage: docker.io/<your-dockerhub-username>/<your-docker-repo-name>
---
apiVersion: kbld.k14s.io/v1alpha1
kind: ImageKeys
keys:
- example
```

Where:
- the first YAML document is a "template" into which `kbld` will rewrite the image reference.
- the remaining YAML documents are configuration for `kbld`, itself.