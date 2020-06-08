# k8s-pool-management

For more detailed info see [this](https://miro.com/app/board/o9J_kujOd6M=/).

Fully automated pipeline that manages our pool of k8s clusters for pipeline and dev work.

check-pool-size; runs frequently and ensure we always have n number of environment available during work hours (7am-6pm).  This can be run manually if you need a cluster out of hours.

post-to-slack; this is the job that posts the reminder to unclaim environments to slack on a Friday.

