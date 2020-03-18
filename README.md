
:exclamation::exclamation::exclamation: This is a highly experimental project to deploy the new CF Kubernetes-centric components on Kubernetes. It is **not** meant for use in production and is subject to change in the future. :exclamation::exclamation::exclamation:

# Cloud Foundry for Kubernetes

- Slack: [#release-integration in Cloud Foundry slack](https://cloudfoundry.slack.com/archives/C0FAEKGUQ), ping `@interrupt`
- [Docs](docs/README.md) with topics about installing, development, etc.
- CI: https://release-integration.ci.cf-app.com/teams/main/pipelines/cf-for-k8s
- Tracker: https://www.pivotaltracker.com/n/projects/1382120

### <a name='purpose'></a> Purpose

Cloud Foundry for Kubernetes (CF4K8s) is a deployment artifact for deploying the Cloud Foundry Application Runtime on Kubernetes. 

- Kubernetes native
  - CF4K8s is built from ground up to leverage Kubernetes native features 
- Built on top of Kubernetes ecosystem projects
  - CF4K8s builts on top of well known enterprise ready projects like [Istio](https://github.com/istio/istio), [envoy](https://github.com/envoyproxy/envoy), [fluentd](https://www.fluentd.org/) and [kpack](https://github.com/pivotal/kpack)

### <a name='deploy'>Deploying CF for K8s</a>

See [Deploying CF for K8s](docs/deploy.md).

### <a name='for-contributors'>For Contributors</a>
See [Contributing](docs/contributing.md)

### <a name='knownissues'></a> Known Issues
This is a highly experimental project, and there are many features missing. For a list of the known issues, take a look at the [GitHub issues tagged 'known-issue'](https://github.com/cloudfoundry/cf-for-k8s/issues?q=is%3Aissue+is%3Aopen+label%3Aknown-issue).

### <a name='future'></a> What's next

Our plan is to release an alpha version of CF4K8s to the community in Feb 2020, which will include build packs based `cf push` experience.

The alpha version will enable the CF project teams to integrate and ship new capabilities for CF4K8s. In addition, we intend to provide a set of tests to validate features before shipping releases.
 
Next up, we plan to build continuous integration (CI) support - a set of CI tasks - which will enable teams to deploy their own pipeline to integrate other components, validate features and cut new releases (just like they do today in the CF4Bosh world). In addition, the release integration team plans to use the same CI tooling to build CF4K8s integration workflows to ship versioned CF4K8s artifacts.

Once we achieve the first two milestones, we intend to explore the CF user needs (platform engineers) to build an enterprise-ready CF4K8s artifact to deploy Cloud Foundry on K8s, with features that CF users are accustomed to today with cf-deployment.
