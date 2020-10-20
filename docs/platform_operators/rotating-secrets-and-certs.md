# Rotating Secrets
Most secrets in cf-for-k8s can be rotated by simply changing the values in your `cf-values.yml` file and running a standard deploy using ytt and kapp. The rotation is complete when the kapp deploy succeeds.

## Exceptions
As of September 2020, it is currently not possible to rotate `app_registry` credentials. Future work on this will be tracked by https://www.pivotaltracker.com/story/show/173090115

### Rotating Ingress Certificates
To rotate the application domain certificate or system domain certificate, you
can do the following:

1. In your `cf-values.yaml`, the system domain certificate is called
`system_certificate` and the application domain certificate is called
`workloads_certificate`. These two properties can be independently updated.
2. Redeploy using ytt and kapp. This will cause the secrets to be recreated and
successfully rotated in the Istio Ingress Gateway.

If you have multiple app domains, they all share the `workloads_certificate`.
You cannot rotate the app domains' certificates separately because there is only
one certificate.


### Cloud Controller Database Encryption Key

Prior to cf-for-k8s 1.0, rotating the cloud controller db encryption key is a breaking change. Rotating the key will 
require a recreating your environment (including deleting database contents) in order to prevent decryption errors when fetching
previously-saved data.

If you find you must rotate the encryption key, 

1. Delete your cf with `kapp delete -a cf`
1. Then, in your `cf-values.yaml`, you will need to update the following property:
```
capi:
  database:
    encryption_key: [KEY]
```
1.Enter a secure value for [KEY] and deploy. 
