# cf-for-k8s-main

## Groups

* cf-for-k8s-main; jobs that test commits to the develop branch of cf-for-k8s
  and merge them to main
* ship-it; jobs used to create new release candidates of cf-for-k8s and convert
  them to final releases

## Release Management

Release management consists of the following steps:

1. Choose whether the next release is going to be a major, minor or patch
   release.
1. Run the corresponding `create-rc-tag-for-*-release` job.
1. Communicate the new version number to SAP for scale testing.
1. If new changes need to be incorporated into the release, run the
   `bump-rc-tag-for-release` job.
1. When the release is ready, run the `finalize-release` job.

### create-rc-tag-for-major-release

This job should be used to create the first release candidate for a new major
release. It will bump the major number in the version file for cf-for-k8s and
append `-rc.1` to the end. It will then tag the commit on the main branch of
cf-for-k8s that most recently passed the promote-main-deliver-stories job with
the new release candidate version.

### create-rc-tag-for-minor-release

This job is identical to the create-rc-tag-for-major-release job, except that it
will bump the minor number in the version file, instead of the major number.

### create-rc-tag-for-patch-release

This job is identical to the create-rc-tag-for-major-release job, except that it
will bump the patch number in the version file, instead of the major number.

### bump-rc-tag-for-release

This job should be used to create a subsequent release candidate for an "in
progress" release. It will only bump the release candidate number in the "rc"
suffix of the current version.

### finalize-release

This job should be used to finalize a release based on the current semantically
"latest" release candidate tag. It will remove the "rc" suffix from the current
version and tag the release candidate commit with the new final release version.

### Notes

See the [Miro board](https://miro.com/app/board/o9J_lckt5J0=/?moveToWidget=3074457352226024090&cot=12)
for initial design notes.
