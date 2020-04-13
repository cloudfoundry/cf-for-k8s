# Debugging

## Error staging application

If you see the following error:
```
Waiting for API to complete processing files...

Staging app and tracing logs...
Error staging application: Stager error: Kpack build failed
FAILED
```
### Possible problems:

#### 1. You may have misconfigured your registry with an invalid host or credentials.

**Next steps:**
* Gather logs by running `cf logs test-app --recent`

| Reason | Message |
|:--|:--|
| Unreachable host. | `OUT prepare:main.go:79: Get https://gcr2.io/v2/: dial tcp: lookup gcr2.io on 10.19.240.10:53: no such host` |
| Invalid credentials. | `OUT prepare:main.go:83: invalid credentials to build to gcr.io/cf-relint-greengrass/cf-workloads/fcdc5e91-1e1a-49b8-a3bf-f8eae7962cc4` |

**How to fix it:**
* Make sure you can login locally with `docker cli` e.g.  `docker login --username USERNAME --password PASSWORD`.
* Make sure you can push / pull images to the the registry.
* Compare your configuration with [examples](https://github.com/cloudfoundry/cf-for-k8s/blob/master/sample-cf-install-values.yml#L123) for different registries in `sample-cf-install-values.yml`.
  * Pay particular attention to `hostname` and `repository` parameters.
