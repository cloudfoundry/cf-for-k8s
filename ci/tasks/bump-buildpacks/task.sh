#!/usr/bin/env bash

set -e

RUBY_SHA=`cat ruby-buildpack/digest`
PYTHON_SHA=`cat python-buildpack/digest`
JAVA_SHA=`cat java-buildpack/digest`
NODEJS_SHA=`cat nodejs-buildpack/digest`
GO_SHA=`cat go-buildpack/digest`
DOTNETCORE_SHA=`cat dotnet-core-buildpack/digest`
PHP_SHA=`cat php-buildpack/digest`
PROCFILE_SHA=`cat procfile-buildpack/digest`

pushd cf-for-k8s-develop
  sed -i "s|^  - image: gcr.io/paketo-buildpacks/ruby@.*$|  - image: gcr.io/paketo-buildpacks/ruby@${RUBY_SHA}| w /dev/stdout" config/kpack/default-buildpacks.yml
  sed -i "s|^  - image: gcr.io/paketo-community/python@.*$|  - image: gcr.io/paketo-community/python@${PYTHON_SHA}| w /dev/stdout" config/kpack/default-buildpacks.yml
  sed -i "s|^  - image: gcr.io/paketo-buildpacks/java@.*$|  - image: gcr.io/paketo-buildpacks/java@${JAVA_SHA}| w /dev/stdout" config/kpack/default-buildpacks.yml
  sed -i "s|^  - image: gcr.io/paketo-buildpacks/nodejs@.*$|  - image: gcr.io/paketo-buildpacks/nodejs@${NODEJS_SHA}| w /dev/stdout" config/kpack/default-buildpacks.yml
  sed -i "s|^  - image: gcr.io/paketo-buildpacks/go@.*$|  - image: gcr.io/paketo-buildpacks/go@${GO_SHA}| w /dev/stdout" config/kpack/default-buildpacks.yml
  sed -i "s|^  - image: gcr.io/paketo-buildpacks/dotnet-core@.*$|  - image: gcr.io/paketo-buildpacks/dotnet-core@${DOTNETCORE_SHA}| w /dev/stdout" config/kpack/default-buildpacks.yml
  sed -i "s|^  - image: gcr.io/paketo-buildpacks/php@.*$|  - image: gcr.io/paketo-buildpacks/php@${PHP_SHA}| w /dev/stdout" config/kpack/default-buildpacks.yml
  sed -i "s|^  - image: gcr.io/paketo-buildpacks/procfile@.*$|  - image: gcr.io/paketo-buildpacks/procfile@${PROCFILE_SHA}| w /dev/stdout" config/kpack/default-buildpacks.yml
  git config user.email "cf-release-integration@pivotal.io"
  git config user.name "relint-ci"
  git add .

  git diff-index --quiet HEAD || git commit -m "Autobump buildpacks"
popd
mkdir -p cf-for-k8s-bumped
cp -R cf-for-k8s-develop/. cf-for-k8s-bumped/
