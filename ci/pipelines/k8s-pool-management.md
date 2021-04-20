# k8s-pool-management

## Purpose

Fully automated pipeline that manages our pool of Kubernetes clusters for pipeline and dev work.

For more detailed info see [this](https://miro.com/app/board/o9J_kujOd6M=/).

## Pool Reconciliation

### Check Pool Size

`check-pool-size`; runs frequently and ensure we always have n number of environments available. This runs during work hours (7am-6pm). 

`check-pool-size-afterhours`'; runs less frequently but still ensures we eventually have an environment available in work week off hours and over the weekend.

You can trigger these jobs manually to expedite the cluster creation process if there are none available.

### Create Cluster

`create-cluster`; claims an environment that has been added to the building pool, provisions it with the [Terraform Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs), and moves its lock to the ready pool for use by CI or devs. Note that clusters created by the `k8s-pool-management` pipeline include wildcard `api` and `system` DNS records for subsequent use by the load balancer services included in many of our cf-for-k8s installations.

**Warning** Do not trigger this job manually as it relies on the existence of a lock in the building pool to use as the basis for resource ids and will wait until it can claim that lock. Instead, use the appropriate check pool size jobs to trigger the creation of a new lock in the building pool.

## Notifications

The pipeline notifies the team of claimed environments periodically as a reminder to unclaim unneeded dev environments and investigate potentially stale build failure environments.

`post-to-slack`; this is the job that posts the reminder to unclaim environments to slack.
