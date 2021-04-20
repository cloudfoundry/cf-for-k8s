# cf-api

## Purpose
This pipeline runs the CAPI K8s component tests and builds the associated
images. It also runs various integration tests (CATs, capi-baras, smoke tests) on cf-for-k8s.

## Groups
- capi-k8s-release: runs unit and integration tests
- ship-it: creates a new Github release

## Validation
There are several jobs in this pipeline that run unit and integration tests to validate the components in capi-k8s-release. The registry-buddy and CF API controller components run go tests while the `cc-tests` job runs `bundle exec rake` against both MySQL and PostgresQL DBs. Once these tests pass, the images are built and deployed along cf-for-k8s develop branch on one of the pooled environments. A subset of [CATs](http://github.com/cloudfoundry/cf-acceptance-tests), [capi-baras](https://github.com/cloudfoundry/capi-bara-tests), and smoke tests are then run against the deployed CF for K8s.


## Image building
This pipeline builds images in two different ways: via [pack](https://github.com/buildpacks/pack) or [oci-build-task](https://github.com/vito/oci-build-task). When building images via pack, the job needs to start up nested docker daemon because pack requires it. The registry-buddy, capi, and cf-api-controllers images are built with pack while the nginx image is built via oci. These images get pushed to the cloudfoundy dockerhub org.

The build image jobs also adds annotations to the images using [deplab](https://github.com/vmware-tanzu/dependency-labeler).


## Release
Once all the validation tests have passed, `the k8s-ci-passed` job updates the image reference templates with the newly build images.

To release a new capi-k8s-release, you must manually trigger the `ship-it-k8s` job. This will grab the latest github release, bumps the minor version, and releases a new minor version of capi-k8s-release.
