| Property | Description  | Required | Default value | Example | Additional options|
| --- | --- | --- | ---| --- | --- |
| system_domain | your system domain | Yes | no value | `system.cf.example.com` | |
| app_domains | list of app domains | Yes | no value | ["apps.cf.example.com"] | |
| cf_admin_password | password for admin user in plain text | Yes | no value | 2fK2zLXPgvmsESrB87sADZQvdLeY5Kv4 | |
| load_balancer.enable | Enable IaaS provisioned load balancer | No | true |  |  |
| load_balancer.static_ip | reserved static ip for LoadBalancer | No | no value | "192.168.0.0" | |
| system_certificate.crt | Certificate for the wildcard - subdomain of the system domain | Yes | no value | CN=*.system.cf.example.com |  |
| system_certificate.key | Private key for the system certificate | Yes | no value |  |  |
| system_certificate.ca | CA certificate used to sign the system certifcate | Yes | no value |  |  |
| workloads_certificate.crt | Certificate for the wildcard - subdomain of the system domain | Yes | no value | CN=*.apps.cf.example.com |  |
| workloads_certificate.key | Private key for the workloads certificate | Yes | no value |  |  |
| workloads_certificate.ca | CA certificate used to sign the workloads certifcate | Yes | no value |  |  |
| gateway.https_only | When true, automatically upgrades incoming HTTP connections to HTTPS gateway | Yes | true |  |  |
| capi.database.adapter | database adapter for use by capi | Yes | no value | postgres | mysql |
| capi.database.encryption_key | key used to encrypt database records at rest | Yes | no value | YqEgP7KxSjUmQTSX9drTkQLye8wrqrP4 |  |
| capi.database.host | address of the database | Yes | no value | `my-postgres.cf.example.com` |  |
| capi.database.port | port on which to make database communication | Yes | no value | 5432 |  |
| capi.database.user | database user for capi tables | Yes | no value | capi-db-user |  |
| capi.database.password | password for the capi database user in plaintext | Yes | no value | d8sQaD9yFWEvBADQE9yFBAt4s5843e6P |  |
| capi.database.name | name of the capi database | Yes | no value | ccdb |  |
| capi.database.ca_cert | authority of the certificate used for tls connections to the database | No | no value |  |  |
| uaa.database.adapter | database adapter for use by uaa | Yes | no value | postgresql | mysql |
| uaa.database.host | address of the database | Yes | no value | `my-postgres.cf.example.com` |  |
| uaa.database.port | port on which to make database communication | Yes | no value | 5432 |  |
| uaa.database.user | database user for uaa tables | Yes | no value | uaa-db-user |  |
| uaa.database.password | password for the uaa database user in plaintext | Yes | no value | d8sQaD9yFWEvBADQE9yFBAt4s5843e6P |  |
| uaa.database.name | name of the uaa database | Yes | no value | ccdb |  |
| uaa.database.ca_cert | authority of the certificate used for tls connections to the database | No | no value |  |  |
| app_registry.hostname | Image registry hostname | Yes | no value | https://index.docker.io/v1/ | https://gcr.io |
| app_registry.repository_prefix | Image registry repository prefix | Yes | no value | my-org |  |
| app_registry.username | Image registry username | Yes | no value | Wingdang |  |
| app_registry.password | Image registry password | Yes | no value | Foobrizzle |  |
| remove_resource_requirements | Remove resource requirements for use on smaller environments | No | false |  |  |
| add_metrics_server_components | Deploy metrics server for clusters that do not include them by default | No | false |  |  |
| use_external_dns_for_wildcard | Enable external-dns integration on the system ingress Service | No | false |  | |
| enable_automount_service_account_token |  | No | false |  |  |
| metrics_server_prefer_internal_kubelet_address |  | No | false |  |  |
| use_first_party_jwt_tokens | Patch istio to use first party jwt tokens | No | false |  |  |
