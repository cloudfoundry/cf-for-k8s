
:exclamation::exclamation::exclamation: This is a highly experimental project to deploy the new CF Kubernetes-centric components on Kubernetes. It is **not** meant for use in production and is subject to change in the future. :exclamation::exclamation::exclamation:

# Cloud Foundry for Kubernetes

- Slack: [#cf-for-k8s in Cloud Foundry slack](https://cloudfoundry.slack.com/archives/CH9LF6V1P), ping `#release-integration @interrupt`
- [Docs](docs/README.md) about installing, development, etc.
- CI: https://release-integration.ci.cf-app.com/teams/main/pipelines/cf-for-k8s
- Tracker: https://www.pivotaltracker.com/n/projects/1382120

### <a name='purpose'></a> Purpose

Cloud Foundry for Kubernetes (CF for K8s) is a deployment artifact for deploying the Cloud Foundry Application Runtime on Kubernetes. 

- Kubernetes native
  - CF for K8s is built from the ground up to leverage Kubernetes native features 
- Built on top of Kubernetes ecosystem projects
  - CF for K8s builds on top of well known enterprise ready projects like [Istio](https://github.com/istio/istio), [envoy](https://github.com/envoyproxy/envoy), [fluentd](https://www.fluentd.org/) and [kpack](https://github.com/pivotal/kpack)

### <a name='deploy'>Deploying CF for K8s</a>

See [Deploying CF for K8s](docs/deploy.md).

### <a name='for-contributors'>For Contributors</a>
See [Contributing](docs/contributing.md)

### <a name='knownissues'></a> Known Issues
This is an experimental project, and there are many features missing. For a list of the known issues, take a look at the [GitHub issues tagged 'known-issue'](https://github.com/cloudfoundry/cf-for-k8s/issues?q=is%3Aissue+is%3Aopen+label%3Aknown-issue).
