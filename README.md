
# Cloud Foundry for Kubernetes
Cloud Foundry is an open source cloud platform as a service (PaaS) on which developers can build, deploy, run and scale applications. Cloud Foundry for Kubernetes (cf-for-k8s) is a Kubernetes native artifact to deploy Cloud Foundry on a Kubernetes cluster. 

For more information on what Cloud Foundry is and how it can help developers build cloud native applications and platform operators to manage those apps at scale, please visit [cloudfoundry.org](https://cloudfoundry.org) and [docs.cloudfoundry.org](https://docs.cloudfoundry.org/)

## Getting Started
See [Deploying CF for K8s](docs/deploy.md) to get your Cloud Foundry up and running on a Kubernetes cluster for development and testing purposes.

## Contributing
Please read [CONTRIBUTING.md](community/CONTRIBUTING.md) for details on the process for submitting pull requests to us.

### Awesome First PR Opportunities
If you're looking to get started today, you can explore the [good first issue](https://github.com/cloudfoundry/cf-for-k8s/issues?q=is%3Aopen+is%3Aissue+label%3A%22Good+first+issue%22) labelled issues in cf-for-k8s repository. 

## Built with
cf-for-k8s is built on top of well known Kubernetes projects like,
- [istio](https://github.com/istio/istio)
- [envoy](https://github.com/envoyproxy/envoy) 
- [fluentd](https://www.fluentd.org/)
- [kpack](https://github.com/pivotal/kpack)
- [paketo buildpacks](https://paketo.io)

## Versioning

We use [SemVer](https://semver.org/) for versioning. For the versions available, see the [releases](https://github.com/cloudfoundry/cf-for-k8s/releases) on this repository.

- TODO: provide documentation for explaining our semantic versioning

## Maintainers

See the list of [MAINTAINERS](community/MAINTAINERS.md) and their contact info.

## License

This project is licensed under the APACHE LICENSE-2.0 - see the [LICENSE.md](LICENSE) file for details.

## CI Pipelines

This project includes a test suite that makes use of Concourse pipelines, which can be found [here](https://release-integration.ci.cf-app.com/teams/main/pipelines/cf-for-k8s).

## Have a question or feedback, reach out to us

We are very active in slack channel [#cf-for-k8s](https://cloudfoundry.slack.com/archives/CH9LF6V1P) in the Cloud Foundry workspace. Please hit us up with any questions you may have or to share your experience with the cf-for-k8s community. To request a fast reponse during Pacific business hours, begin your message with `#release-integration @interrupt`
