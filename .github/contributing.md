# Contributing

1. Ensure you are up to date with the `master` branch
1. Create a branch in this repo
   - If you do not have access to creating branches and believe you should,
     please inquire in the [#release-integration](https://cloudfoundry.slack.com/archives/C0FAEKGUQ) slack channel
   - Otherwise please submit changes from a fork
1. If you are adding/updating a ytt library, ensure you update the top-level
   `vendir.yml`, run `vendir sync`, and ensure your changes to `config/_ytt_lib`
   and `vendir.lock.yml` for this new/updated ytt library are committed in your proposed changes
   - If you are using a git-based library, note that you can use commit SHAs
     or tags as references
1. If you are adding/updating data values, please also add those changes to the
   `sample-cf-install-values.yml` file
1. Before submitting, please ensure you have deployed and [run smoke
   tests](../docs/development.md#smoke-tests-1)
1. Push your changes to your branch/fork
1. Create a pull request
