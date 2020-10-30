# Updating Supported Kubernetes Versions

## Definitions

* N = the newest version of K8s that we support

* N-X = the oldest version that we support

## Updating Newest Supported Version
###Steps

1. We've decided it’s time to start work on updating the newest version of Kubernetes we support (usually updating our N to be current N+1)
1. Begin testing cf-for-k8s against N+1.

   a. spin up kind cluster on K8s version N+1
   
   b. attempt deploying cf-for-k8s. Make list of affected deprecated APIs (if any)
   
   c. (if necessary) manually update to new APIs and try deploying again. (repeat until all have been updated)
   
   d. Attempt running smoke tests. Make note of failures and begin [timeboxed] debugging
      - we expect to frequently have API deprecations that break cf-for-k8s installation
      - we also expect that updating will sometimes break functionality
      - Q: Can we make use of **kubectl convert** or something similar?
      - Outcome: Github issues for all affected component teams about what updates we need from them to support N+1
      
1. Create a master issue in cf-for-k8s that links to all these issues required to support K8s version N+1
1. File an issue in the component repository. Add a link to issue to the master issue
1. Contributing teams PR-in their changes for N+1 compatibility (for the requested changes)
   - N-X PR gate might start failing due to this change. (We expect N-X to fail a good % of the time that we shift to supporting N+1)
   - Note, we cannot bump N to be N+1 until all necessary component team updates have been incorporated (keep CI green)

1. Once all relevant PRs are merged, manually deploy and validate (ie run smoketests) on an N+1 cluster.
1. Update [the list of supported versions](../../supported_k8s_versions.yml)

## Updating Oldest Supported Version
Disclaimer: We need to add more detail here, but these were the top of my mind concerns when we bumped from 1.15 to 1.16.
1. Updating the oldest supported version will not require handling deprecations as the newest version already acts as a forcing function on that front
1. With a new oldest version we gain access to new apis across the supported version window, in particular promoted apis
1. Aside from api concerns, users of cf-for-k8s may have concerns moving their cluster forward, so we would like to check with the Community before bumping
