# QUARKS SECRET

## Introduction

This helm chart deploys the quarks-secret operator.

## Installing the Latest Stable Chart

To install the latest stable helm chart, with `quarks-secret` as the release name into the namespace `quarks`:

```bash
helm repo add quarks https://cloudfoundry-incubator.github.io/quarks-helm/
helm install quarks-secret quarks/quarks-secret
```

### Namespaces

The operator runs on every namespace that has the monitoredID label (quarks.cloudfoundry.org/monitored).

```
helm install relname1 quarks/quarks-secret \
  --set "global.monitoredID=relname1"
```

## Installing the Chart From the Developmenet Branch

Download the shared scripts with `bin/tools`, set `PROJECT=quarks-secret` and run `bin/build-image` to create a new docker image. Export `DOCKER_IMAGE_TAG` to override the tag that's being put in the chart.

To install the helm chart directly from the [quarks-secret repository](https://github.com/cloudfoundry-incubator/quarks-secret) (any branch), run `bin/build-helm` first.

## Uninstalling the Chart

To delete the helm chart:

```bash
$ helm delete quarks-secret --purge
```

## Configuration

| Parameter                                         | Description                                                                            | Default                                        |
| ------------------------------------------------- | -------------------------------------------------------------------------------------- | ---------------------------------------------- |
| `global.contextTimeout`                           | Will set the context timeout in seconds, for future K8S API requests                   | `30`                                           |
| `global.image.pullPolicy`                         | Kubernetes image pullPolicy                                                            | `IfNotPresent`                                 |
| `global.monitoredID`                              | Label value of 'quarks.cloudfoundry.org/monitored'. Matching namespaces are watched    | release name                                   |
| `global.rbac.create`                              | Install required RBAC service account, roles and rolebindings                          | `true`                                         |
| `serviceAccount.create`                           | If true, create a service account                                                      | `true`                                         |
| `serviceAccount.name`                             | If not set and `create` is `true`, a name is generated using the fullname of the chart |                                                |

## RBAC

By default, the helm chart will install RBAC ClusterRole and ClusterRoleBinding based on the chart release name, it will also grant the ClusterRole to an specific service account, which have the same name of the chart release.

The RBAC resources are enable by default. To disable use `--set global.rbacEnable=false`.

## Custom Resources

The `quarks-secret` watches for the `QuarksSecret` custom resource.

The `quarks-secret` requires this CRD to be installed in the cluster, in order to work as expected. By default, the `quarks-secret` applies the CRD in your cluster automatically.

To verify if the CRD is installed:

```bash
$ kubectl get crds
NAME                                            CREATED AT
quarkssecrets.quarks.cloudfoundry.org           2019-06-25T07:08:37Z
```
