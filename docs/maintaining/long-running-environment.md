# cf-for-k8s long-running environment (LRE)

The general idea for our long-running environment is to run it similarly to a production cf-for-k8s, and to measure useful uptime measurements (SLIs) that we can share with stakeholders about the stability of the platform.

## Normal operation

### Nightly Upgrades

The [long-lived-env section of the cf-for-k8s stability pipeline](https://release-integration.ci.cf-app.com/teams/main/pipelines/cf-for-k8s-stability-tests?group=long-lived-env) houses our pipeline jobs that are responsible for deploying and upgrading the LRE. Every weeknight, the environment is automatically updated to the latest HEAD of main.

### SLIs / Recurring Measurements

see https://github.com/cloudfoundry/cf-for-k8s/blob/develop/docs/platform-availability.md#availability-during-normal-operation, which explains the SLIs and includes some SLI results, at least from the weeks leading up to the 1.0 release.

For configuring the Pingdom Uptime check, Release Integration team members have access to https://my.pingdom.com/app/reports/uptime#check=6350471 through the cf-mega@pivotal.io Pingdom account in Lastpass.

## Infrastructure

We have pipeline jobs in the _private_ [cf-for-k8s-dev-tooling pipeline](https://release-integration.ci.cf-app.com/teams/main/pipelines/cf-for-k8s-dev-tooling?group=long-lived-sli-cluster) to destroy or create the "long-lived-sli cluster" using terraform.

## Troubleshooting

In the spirit of the purpose of this environment, we strive to fix the environment using the most tightly-scoped fixes possible. Here are some troubleshooting options in increasingly drastic order:

1) Fix the root problem in cf-for-k8s
1) Re-push the long-running app using the [deploy-long-lived-node-app job](https://release-integration.ci.cf-app.com/teams/main/pipelines/cf-for-k8s-stability-tests/jobs/deploy-long-lived-node-app)
1) Re-run the platform upgrade / `kapp deploy` job: [upgrade-long-lived-env-to-latest-main](https://release-integration.ci.cf-app.com/teams/main/pipelines/cf-for-k8s-stability-tests/jobs/upgrade-long-lived-env-to-latest-main)
1) Restarting K8s pods
  - to target the cluster, run `gcloud container clusters get-credentials long-lived-sli --zone us-central1-a --project cf-relint-greengrass`
  - the cf-values file for the LRE can be found here: `relint-envs/k8s-environments/long-lived-sli/cf-values.yaml`
1) Tearing down and standing back up the environment, using the destroy and create jobs in [cf-for-k8s-dev-tooling/long-lived-sli-cluster](https://release-integration.ci.cf-app.com/teams/main/pipelines/cf-for-k8s-dev-tooling?group=long-lived-sli-cluster)
