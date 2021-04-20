# cf-for-k8s-stability-tests

## Purpose
All jobs use `long-lived-sli` cluster created by the `cf-for-k8s-dev-tooling` pipeline.

### Long-lived environment 
Updated with the latest from `cf-for-k8s` main every weeknight

### SLIs 
Run smoke tests every minute and emit success/failure metrics to Wavefront

### Validate value rotation and upgrade 
Runs every weeknight. Updates the `cf-for-k8s` deployment with rotated values (for all that are safe to rotate) and
confirms the result passes smoke tests and that previously-pushed apps are still running.

