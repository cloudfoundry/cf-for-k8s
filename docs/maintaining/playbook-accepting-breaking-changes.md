# Accepting Breaking Changes

## Summary

We occasionally expect PRs to break upgrades.

The idea is that we should be aware of these breakages, make sure they're expected and necessary, and then relay the information to the community.

## Playbook

1. Confirm with PR author that the upgrade breakage is expected and necessary. Make sure the rationale is documented on the PR.
1. Confirm that all PR tests other than the upgrade test are passing.
1. Merge the PR.
1. Add the breakage as a row to this google doc: [cf-for-k8s upgrade breaking commits](https://docs.google.com/spreadsheets/d/1eJEOJg7WLqL8n_S-woKAMYGunh9jyhI0sFMScmxi9F4/edit#gid=0)
1. Announce the breaking change in #cf-for-k8s.
