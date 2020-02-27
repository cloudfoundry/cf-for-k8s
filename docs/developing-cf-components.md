# Developing CF Components

## Additional Dependencies
In addition to the core build dependencies: [/docs/development.md#dependencies](/docs/development.md#dependencies), the workflow herein uses these tools:

- [kbld](https://get-kbld.io/)
- [minikube](https://github.com/kubernetes/minikube)

## Component Repository Organization
To simplify the component development workflow, we recommend repositories organize configuration thusly:

```
├── example-component
│   ├── config               - K8s resources
│   │   ├── deployment.yml
│   │   ├── service.yml
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

## Potential Workflow
1. Checkout `cf-for-k8s` master and install it to your cluster
1. Start a minikube with sufficient memory (we used 8GB in our workflow prototype) and expose its local docker daemon
    ```
    minikube start
    eval $(minikube docker-env)
    docker login -u ...
    ```
1. Make changes to your component
1. Rebuild your component image with `kbld` and generate a data value file with that resolved image reference
    ```
    cd ~/workspace/example-component
    cat >config/values/images.yml \
        <(echo "#@data/values"; kbld -f config/build/kbld.yml --images-annotation=false)
    ```
    _Note: `ytt` merges data files in alphabetical order of the full pathname.  So, `config/values/_default.yml` is used first, THEN `config/values/images.yml` (see [k14s/ytt/ytt-data-values](https://github.com/k14s/ytt/blob/master/docs/ytt-data-values.md#splitting-data-values-into-multiple-files))._

    Therefore, it is critical that whatever name you choose for the generated data file (here, `images.yml`), it sorts _after_ `_default.yml`.

    See [kbld docs](https://github.com/k14s/kbld/blob/master/docs/config.md) to configure your own `kbld.yml`.

1. Sync your local component configuration into the `cf-for-k8s` repo with vendir's [`--directory`](https://github.com/k14s/vendir/blob/985506a54038f6e7871879d4fbee9df2b6cf8add/docs/README.md#sync-with-local-changes-override)
    ```
    cd ~/workspace/cf-for-k8s
    vendir sync \
      --directory config/_ytt_lib/github.com/cloudfoundry/capi-k8s-release=~/workspace/capi-k8s-release/
    ```
1. Re-deploy `cf-for-k8s` with your updated component
