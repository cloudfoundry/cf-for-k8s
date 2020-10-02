# Setup ingress certs with Lets Encrypt
The following instructions will setup ingress certs with Lets Encrypt. You have the option of setting up certs before install or update an existing install with the new certs.

## Objective
At the end of this setup, you and your users will be able to access CF CLI and CF APPs over HTTPS.

## Prerequisites

- `certbot` cli
   - For Mac, run `brew install certbot`. For other linux distros, see instructions on [certbot site](https://certbot.eff.org/instructions) [1].
- Permissions to add/update DNS `A` and `TXT` records.

[1] On `certbot` site, the web server and os is irrelevant. You will be generating the certs on your machine, so choose the os that matches your os.

## Steps to setup ingress certs
The following instructions assume that the system domain is setup at `pm-k8s.dev.relint.rocks` and the apps domain is setup at `apps.pm-k8s.dev.relint.rocks`. You can update the domains accordingly.

### System domain

1. Set the environment variable for sys domain
```console
export SYS_DOMAIN=pm-k8s.dev.relint.rocks
```
2. Generate a cert for the system domain
```console
certbot --server https://acme-v02.api.letsencrypt.org/directory -d "*.$SYS_DOMAIN" --manual \
    --preferred-challenges dns-01 certonly \
    --work-dir /tmp/certbot/wd --config-dir /tmp/certbot/cfg \
    --logs-dir /tmp/certbot/logs
```
3. You will be presented with a challenge to verify domain ownership. Copy the `TXT`value printed by certbot and create a TXT record in your DNS provider.
```console
# example of the TXT in your DNS
_acme-challenge.SYS_DOMAIN.	TXT    kyfxzsAirB79lsk173jkdlamxiryqloy
```
4. Wait for the TXT record to propagate to the nameservers. You can `dig` tool in a separate console to verify the TXT is updated
```console
dig _acme-challenge.$SYS_DOMAIN TXT
```
5. In the certbot console, press enter once the TXT change is propagated to nameservers. `certbot` will verify that you own the server and create the necessary files.

### Apps domain
Let's now create apps domain certs

1. Set environment variable for the apps domain
```console
export APPS_DOMAIN=apps.pm-k8s.dev.relint.rocks
```
2. Generate a cert for the workloads domain
```console
certbot --server https://acme-v02.api.letsencrypt.org/directory -d "*.$APPS_DOMAIN" --manual \
    --preferred-challenges dns-01 certonly \
    --work-dir /tmp/certbot/wd --config-dir /tmp/certbot/cfg \
    --logs-dir /tmp/certbot/logs
```
3. You will be presented with a challenge to verify domain ownership. Copy the `TXT`value printed by certbot and create a TXT record in your DNS provider.
```console
# example of the TXT in your DNS
_acme-challenge.$APPS_DOMAIN.	TXT    kyfxzsAirB79lsk173jkdlamxiryqloy
```

### Update cf-values yaml
The following instructions assume you have created `cf-install-values.yml`. Please ensure to copy the file contents into the variables as is.

1. **Update system certificate values**

    Lookup `system_certificate` in `cf-install-values.yml`. You should config variables `crt`, `key` and `ca`. Follow the instructions below,
    ```yaml
    system_certificate:
      crt: <replace this with the contents of the file /tmp/certbot/cfg/live/$SYS_DOMAIN/fullchain.pem>
      key: <replace this with the contents of the file /tmp/certbot/cfg/live/$SYS_DOMAIN/privkey.pem>
      ca: "" #! replace whatever old value with empty string
    ```
    Your final output for `system_certificate` will look something like
    ```yaml
    system_certificate:
      crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUZhakNDQkZLZ0F3SUJBZ0lTQ....
      key: LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUV2Z0lCQURBTkJna3Foa2...
      ca: ""
    ```

1. **Update apps certificate values**

   The `workloads_certificate` has sub-keys `crt`, `key`, `ca` under it.
   ```yaml
   workloads_certificate:
      crt: <replace this with the contents of the file /tmp/certbot/cfg/live/$APPS_DOMAIN/fullchain.pem>
      key: <replace this with the contents of the file /tmp/certbot/cfg/live/$APPS_DOMAIN/privkey.pem>
      ca: "" #! replace whatever old value with empty string
   ```

1. Follow the instructions from deploy doc to generate the final deploy yml using `ytt` and `kapp` to deploy cf-for-k8s to your cluster.

### Verify TLS

1. Connect to the cf api without skipping the ssl validation
```console
cf api https://api.$SYS_DOMAIN
```
Follow instructions in deploy doc to setup your org/spaces and cf push an app (if you haven't already).

2. Verify app domain certs by running `curl -vvv` or verify the cert in a browser

```console
curl -vvv  https://$APP_NAME.$APPS_DOMAIN
# output should show `SSL certificate verify ok`
```
