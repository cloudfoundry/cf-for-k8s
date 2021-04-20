# cf-for-k8s-experimental

## Purpose

This pipeline provides compatibility information for cf-for-k8s experimental features and configuration that are not directly supported and validated by the main cf-for-k8s pipelines. At this time, the QuarksSecret secret generation controller is the only experimental feature in the repo.

## Validation Strategy

Given the experimental status of the features validated in the pipeline, the pipeline validates a minimal fresh installation on a GKE cluster with cf-for-k8s smoke-tests. Validation runs on the slower cadence of once per week, but still against the `develop` branch.

## Configuration for Validation

Experimental features are disabled by default and enabled through an experimental feature flag in the [ytt data values](https://carvel.dev/ytt/docs/latest/ytt-data-values/) configuration interface. There may be additional required configuration, but the feature flag at a minimum will be present.

In general these feature flags exist in the data values file `config/values/##-experimental-values.yml`. Currently, we have `30-experimental-values.yml` within which exists the following yaml structure:

```
experimental:
  <feature_name>:
    enable: false
```

So to enable an experimental feature, we set the `experimental.feature_name.enable` flag to `true` in line with the yaml configuration structure outlined above by threading through a param on the concourse task responsible for installing cf-for-k8s (in this case `install-cf-on-gke`). In general, threading a data value through requires a param that conditionally appends the data value struct outlined above to the data values file used for installation.

### Quarks Secret

To enable Quarks Secret, we set the `experimental.quarks_secret.enable` flag to `true` and explicitly do not generate and/or provide our own secret values to the data values file.
