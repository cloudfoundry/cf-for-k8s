Default values are set in files like `config/values/00-values.yml`

| Property | Description  | Required | Default value | Example |
| --- | --- | --- | --- | --- |
| add_metrics_server_components | Deploy metrics server for clusters that do not include them by default | No | false |  |
| allow_prometheus_metrics_access | Allows any Prometheus server scrape access to metrics endpoints | No | false |  |
| app_domains | list of app domains | Yes | no value | ["apps.cf.example.com"] |
| app_registry.hostname | Image registry hostname | Yes | no value | https://index.docker.io/v1/ | https://gcr.io |
| app_registry.password | Image registry password | Yes | no value | Foobrizzle |
| app_registry.repository_prefix | Image registry repository prefix | Yes | no value | my-org |
| app_registry.username | Image registry username | Yes | no value | Wingdang |
| blobstore.secret_access_key | Blobstore secret access key | Yes | no value | Potrzebie |
| capi.cc_username_lookup_client_secret | CF API client secret | Yes | no value | o/L4Zsu6ZAgw4+Qj |
| capi.cf_api_controllers_client_secret | API controller client secret | Yes | no value | q/3PZsu6ZAgw4+Qj |
| capi.database.adapter | database adapter for use by capi | No | postgres | postgres | mysql |
| capi.database.ca_cert | authority of the certificate used for tls connections to the database | No | no value |  |
| capi.database.encryption_key | key used to encrypt database records at rest | Yes | no value | YqEgP7KxSjUmQTSX9drTkQLye8wrqrP4 |
| capi.database.host | address of the database | No | no value | `my-postgres.cf.example.com` |
| capi.database.name | name of the capi database | No | cloud_controller | ccdb |
| capi.database.password | password for the capi database user in plaintext | Yes | no value | d8sQaD9yFWEvBADQE9yFBAt4s5843e6P |
| capi.database.port | port on which to make database communication | No | 5432 | 3306 |
| capi.database.user | database user for capi tables | No | cloud_controller | capi-db-user |
| cf_admin_password | password for admin user in plain text | Yes | no value | 2fK2zLXPgvmsESrB87sADZQvdLeY5Kv4 |
| cf_db.admin_password | password for administering the internal database | Not if using external database | no value | FQq3dPd6DAoLIMIr |
| enable_automount_service_account_token |  | No | false |  |
| gateway.https_only | When true, automatically upgrades incoming HTTP connections to HTTPS gateway | No | true | false |
| load_balancer.enable | Enable IaaS provisioned load balancer | No | true | false |
| load_balancer.static_ip | reserved static ip for LoadBalancer | No | dynamically assigned | "192.168.0.0" |
| metrics_server_prefer_internal_kubelet_address |  | No | false |  |
| remove_resource_requirements | Remove resource requirements for use on smaller environments | No | false |  |
| system_certificate.ca | CA certificate used to sign the system certifcate | No | no value |  |
| system_certificate.crt | Certificate for the wildcard - subdomain of the system domain | Yes | no value | CN=*.system.cf.example.com |
| system_certificate.key | Private key for the system certificate | Yes | no value |  |
| system_domain | your system domain | Yes | no value | `system.cf.example.com` |
| uaa.admin_client_secret | Admin client secret for UAA | Yes | no value | 44Ae8Oc90lap7VxO |
| uaa.database.adapter | database adapter for use by uaa | No | postgresql | mysql |
| uaa.database.ca_cert | authority of the certificate used for tls connections to the database | No | no value |  |
| uaa.database.host | address of the database | No | no value | `my-postgres.cf.example.com` |
| uaa.database.name | name of the uaa database | No | uaa | uaa-db |
| uaa.database.password | password for the uaa database user in plaintext | Yes | no value | d8sQaD9yFWEvBADQE9yFBAt4s5843e6P |
| uaa.database.port | port on which to make database communication | No | 5432 | 3306 |
| uaa.database.user | database user for uaa tables | No | uaa | uaa-db-user |
| uaa.encryption_key.passphrase | passphrase for UAA encryption key | Yes | no value | oMPQAK3stj+CeG0F |
| uaa.jwt_policy.signing_key | JWT policy configuration signing key | Yes | no value | 9CsV45r5NFe0z8mC |
| uaa.login.service_provider.certificate | certificate for UAA's SAML provider | Yes | no value | plD9e2dUSbXISO6H |
| uaa.login.service_provider.key | key for UAA's SAML provider | Yes | no value | qcXZEcKlrG/8mCfH |
| uaa.login_secret | secret for an external login server to authenticate to UAA | Yes | no value | xrEL+uJ4eb8duBms |
| use_external_dns_for_wildcard | Enable external-dns integration on the system ingress Service | No | false |  |
| use_first_party_jwt_tokens | Patch istio to use first party jwt tokens | No | false |  |
| workloads_certificate.ca | CA certificate used to sign the workloads certifcate | No | no value |  |
| workloads_certificate.crt | Certificate for the wildcard - subdomain of the system domain | Yes | no value | CN=*.apps.cf.example.com |
| workloads_certificate.key | Private key for the workloads certificate | Yes | no value |  |
