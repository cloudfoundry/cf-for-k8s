# A Word of Caution for Operators
Operators are welcome to "peek into the system" using `kubectl`. However, direct
modification on cluster resources can lead to unexpected consequences. Many
controllers have not yet built in any tolerance for direct user interaction with
internal components, such as Istio and Fluentd. At the moment, some of our
controllers don't actively reconcile: if someone modifies a resource belonging
to CloudFoundry using `kubectl`, it could introduce conflicting configurations
that CF is not able to handle. For example, if you modify a Route Custom
Resource's hostname, the change will not be reflect when using the `cf` CLI.

