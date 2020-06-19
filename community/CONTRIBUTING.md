# Contributing to cf-for-k8s

The following sections outline the process to contribute to cf-for-k8s.

- [Code of conduct](#code-of-conduct)
- [Contributor license agreements](#contributor-license-agreements)
- [Project Management Committee](#project-management-committee)
- [Setting up to contribute](#setting-up-to-contribute)
- [Pull requests](#pull-requests)
  - [Getting started with contribution](#getting-started-with-contribution)
- [Contributing a feature](#contributing-a-feature)

## Code of conduct

All members of the cf-for-k8s community must abide by the [Code of Conduct](community/code-of-conduct.md). Only by respecting each other can we develop a productive, collaborative community. If you would like to report a violation of the code of contact, please contact any member from the [Maintainers list](MAINTAINERS.md).

## Contributor license agreements

We'd love to accept your contributions! But before we can take them, you will have to fill out the [EasyCLA](https://lfcla.com/).

Once you are CLA'ed, we'll be able to accept your pull requests.

## Project Management Committee

The cf-for-k8s is maintained by projects that are governed by the Project Management Committee (PMC). Any contribution to cf-for-k8s should be started by first engaging with the appropriate project group. You can find the full list of projects, their leads and contact information [here](https://docs.google.com/spreadsheets/d/1hg0EA3aB9wiCq8SgCU90ft4qrHvczsUjK0W_31APWxM/edit#gid=0).

## Setting up to contribute

Check out [preparing for development](PREPARING-FOR-DEVELOPMENT.md) to learn about how to setup your local dev environment with cf-for-k8s.

## Pull requests

If you're working on an existing issue, simply respond to the issue and express interest in working on it. This helps other people know that the issue is active, and hopefully prevents duplicated efforts.

To submit a proposed change:

- Fork the affected repository.
- Create a new branch for your changes.
- Develop/fix the code.
- Add new test cases as applicable. In the case of a bug fix, the tests should fail without your code changes. For new features try to cover as many variants as reasonably possible.
- Update the docs as applicable.

When ready, if you have not already done so, sign a contributor license agreements and submit the PR. The PR checks will run unit tests and validate your changes with a `kapp deploy` and a run of `smoketests`. If there are failures, check out the individual checks to debug the issue and don't hesitate to ping the members in #cf-for-k8s slack channel for help.

### Getting started with contribution

If you're looking to get started today, you can explore the [good first issue](https://github.com/cloudfoundry/cf-for-k8s/issues?q=is%3Aopen+is%3Aissue+label%3A%22Good+first+issue%22) labelled issues in cf-for-k8s repository. 

If you're looking to take on more, you can explore the [help wanted](https://github.com/cloudfoundry/cf-for-k8s/issues?q=is%3Aopen+is%3Aissue+label%3A%22Help+wanted%22) labelled issues to get started.

You can create [issues](https://github.com/cloudfoundry/cf-for-k8s/issues) to report bugs or submit feature requests. The approporate templates will guide you to fill the key pieces of information. To check for relevant existing issues/reports

## Contributing a feature

In order to contribute a feature to cf-for-k8s, you'll need to go through the following steps:

- First, create a feature request issue type in cf-for-k8s repository. The issue should include information about the requirements and use cases that it is trying to address. Include a discussion of the proposed design and technical details of the implementation in the issue.

- If the feature is substantial enough, a project team member may ask for architecture design doc. Create the design document in google doc and add a link to the GitHub issue. Update the projects by sending an email to cf-dev@cloudfoundry.org mailing list and/or via slack channel. Depending on the complexity and the breadth of the feature request, the project team may discuss in one of the special interest groups or during runtime PMC meetings or they might directly involve relevant projects before being approved.

- Submit PRs to the respective project repository with your code changes. Include relevant documentation changes and tests in your PR.

> Note that we prefer bite-sized PRs instead of giant monster PRs. It's therefore preferable if you can introduce large features in smaller reviewable changes that build on top of one another.

## Have a question or feedback, reach out to us

We are very active in slack channel [#cf-for-k8s](https://cloudfoundry.slack.com/archives/CH9LF6V1P) in the Cloud Foundry workspace. Please hit us up with any questions you may have or to share your experience with the cf-for-k8s community. To request a fast reponse during Pacific business hours, begin your message with `#release-integration @interrupt`
