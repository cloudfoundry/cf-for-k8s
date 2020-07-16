# Using external databases


You can use an external database for the cloud controller and uaa by providing following values:

```yaml
#@data/values
---
capi:
  database:
    adapter: postgres
    host: <host>
    port: <port>
    user: <user>
    password: <password>
    name: <database>
    ca_cert: <ca certificate for tls>

uaa:
  database:
    adapter: postgresql
    host: <host>
    port: <port>
    user: <user>
    password: <password>
    name: <database>
    ca_cert: <ca certificate for tls>
```


Please note to the **different spelling** of `postgres`  and `postgresql` for capi and uaa.


## Limitations

Providing a `ca_cert` enables SSL full verification. SQL database services that do not have a hostname and certificate valid for that hostname (e.g. GCP Cloud SQL) will not be able to negotiate a connection in this mode. Skipping hostname validation is not supported.

## Setup

As prerequisite, you need to execute the following steps to configure your postgres installation for cf-for-k8s:

1. Set the environment variables

    ```bash
    export VALUES_FILE=<path to file from above>
    export PGPASSWORD=<password of postgres super user>
    export PGHOST=<host where postres is running>
    ```

2. Run the following script. It will
   * create one database each for Cloud Controller and UAA
   * create one user each for Cloud Controller and UAA
   * activate the `citext` extension for each of these databases

    The following uses the python module [yq](https://kislyuk.github.io/yq/).
    ```bash
    CCDB_USERNAME=$(yq -r '.capi.database.user' "$VALUES_FILE")
    CCDB_PASSWORD=$(yq -r '.capi.database.password' "$VALUES_FILE")
    CCDB_NAME=$(yq -r '.capi.database.name' "$VALUES_FILE")
    UAADB_USERNAME=$(yq -r '.uaa.database.user' "$VALUES_FILE")
    UAADB_PASSWORD=$(yq -r '.uaa.database.password' "$VALUES_FILE")
    UAADB_NAME=$(yq -r '.uaa.database.name' "$VALUES_FILE")
    cat > /tmp/setup_db.sql <<EOT
    CREATE DATABASE ${CCDB_NAME};
    CREATE ROLE ${CCDB_USERNAME} LOGIN PASSWORD '${CCDB_PASSWORD}';
    CREATE DATABASE ${UAADB_NAME};
    CREATE ROLE ${UAADB_USERNAME} LOGIN PASSWORD '${UAADB_PASSWORD}';
    EOT
    psql -U postgres -f /tmp/setup_db.sql
    psql -U postgres -d "${CCDB_NAME}" -c "CREATE EXTENSION citext"
    psql -U postgres -d "${UAADB_NAME}" -c "CREATE EXTENSION citext"
    ```
    To use the Golang [yq](https://github.com/mikefarah/yq) utility, use these assignments.
    ```
    ```bash
    CCDB_USERNAME=$(yq read "$VALUES_FILE" 'capi.database.user')
    CCDB_PASSWORD=$(yq read "$VALUES_FILE" 'capi.database.password')
    CCDB_NAME=$(yq read "$VALUES_FILE" 'capi.database.name')
    UAADB_USERNAME=$(yq read "$VALUES_FILE" 'uaa.database.user')
    UAADB_PASSWORD=$(yq read "$VALUES_FILE" 'uaa.database.password')
    UAADB_NAME=$(yq read "$VALUES_FILE" 'uaa.database.name')
    ...
    ```

## Installation of an internal database

If both, capi and uaa, are configured to use an external database, no internal database will be deployed.
