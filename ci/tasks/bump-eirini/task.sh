#!/bin/bash -eux

TAG=$(cat eirini-release/tag)
pushd cf-for-k8s-develop > /dev/null
  cat <<EOT > /tmp/bump-eirini-overlay.yml
#@ load("@ytt:overlay", "overlay")

#@overlay/match by=overlay.subset({})
---
directories:
#@overlay/match by="path"
- path: build/eirini/_vendir
  contents:
    #@overlay/match by="path"
    - path: .
      githubRelease:
        #@overlay/replace
        tag: ${TAG}
EOT
  ytt -f vendir.yml -f /tmp/bump-eirini-overlay.yml --ignore-unknown-comments=true > /tmp/vendir.yml && cp /tmp/vendir.yml vendir.yml
  vendir sync
  pushd build/eirini > /dev/null
    ./build.sh
  popd > /dev/null

  git config user.email "cf-release-integration@pivotal.io"
  git config user.name "relint-ci"
  git add .
  git commit -m "Bump eirini to ${TAG}"

popd > /dev/null

cp -r cf-for-k8s-develop/. cf-for-k8s-bump
