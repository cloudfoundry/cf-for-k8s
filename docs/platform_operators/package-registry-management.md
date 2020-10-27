# Package Registry Management

## Delete images from Harbor package registry

If you are using Harbor as a package registry and a package gets deleted or when an expired package is cleaned up, an empty repository remains even when the image itself is deleted. As an operator, you may want to clean up these empty repos and there are two ways to do that both from the Harbor registry UI: 

1. Navigate to the empty repo in Harbor, select the empty repo, click on the three dots in the top right corner and hit `delete`

1. Clean up all the empty repos by [running the garbage collection](https://goharbor.io/docs/2.1.0/administration/garbage-collection/) 
  - Run this adhoc by going to the `Run Garbage Collection` tab under `Harbor Administration` 
  - It is also possible to schedule a garbage collection job using a cron job