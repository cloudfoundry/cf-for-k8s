# UAA

To target and authenticate with the UAA:

```plain
cf_values=/tmp/cf-values.yml

uaa target  "https://uaa.$(bosh int "$cf_values" --path /system_domain)" --skip-ssl-validation
uaa get-client-credentials-token admin --client_secret $(bosh int  "$cf_values" --path /uaa/admin_client_secret)
```

You can now run `uaa` commands to fetch or set UAA configuration.

For example, to get the list of registered clients (applications that want to authorize via UAA):

```plain
$ uaa list-clients | jq -r ".[].client_id"
admin
capi_kpack_watcher
cf
cf-k8s-networking
cloud_controller_username_lookup
```
