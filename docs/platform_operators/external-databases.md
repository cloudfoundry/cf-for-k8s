# Using external databases


You can use an external database for the cloud controller and uaa by providing following values:

```yaml
#@data/values
---
capi:
  #@overlay/replace
  database:
    adapter: postgres
    host: <host>
    port: <port>
    user: <user>
    password: <password>
    name: <database>
    ca_cert: <ca certificate for tls>

uaa:
  #@overlay/replace
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
    export PGPASSWORD=<password of postgres super user>
    export PGHOST=<host where postres is running>
    export DB_VALUES_FILE=db-values.yml
    ```

2. Run the following script. It will
   * create one database each for Cloud Controller and UAA
   * create one user each for Cloud Controller and UAA
   * activate the `citext` extension for each of these databases

    The following uses the python module [yq](https://kislyuk.github.io/yq/).
    ```bash
    CCDB_USERNAME=$(yq -r '.capi.database.user' "$DB_VALUES_FILE")
    CCDB_PASSWORD=$(yq -r '.capi.database.password' "$DB_VALUES_FILE")
    CCDB_NAME=$(yq -r '.capi.database.name' "$DB_VALUES_FILE")
    UAADB_USERNAME=$(yq -r '.uaa.database.user' "$DB_VALUES_FILE")
    UAADB_PASSWORD=$(yq -r '.uaa.database.password' "$DB_VALUES_FILE")
    UAADB_NAME=$(yq -r '.uaa.database.name' "$DB_VALUES_FILE")
    cat > "$TMPDIR/setup_db.sql" <<EOT
    CREATE DATABASE ${CCDB_NAME};
    CREATE ROLE ${CCDB_USERNAME} LOGIN PASSWORD '${CCDB_PASSWORD}';
    CREATE DATABASE ${UAADB_NAME};
    CREATE ROLE ${UAADB_USERNAME} LOGIN PASSWORD '${UAADB_PASSWORD}';
    EOT
    psql -U postgres -f "$TMPDIR/setup_db.sql"
    psql -U postgres -d "${CCDB_NAME}" -c "CREATE EXTENSION citext"
    psql -U postgres -d "${UAADB_NAME}" -c "CREATE EXTENSION citext"
    ```
    To use the Golang [yq](https://github.com/mikefarah/yq) utility, use these assignments.
    ```bash
    CCDB_USERNAME=$(yq read "$DB_VALUES_FILE" 'capi.database.user')
    CCDB_PASSWORD=$(yq read "$DB_VALUES_FILE" 'capi.database.password')
    CCDB_NAME=$(yq read "$DB_VALUES_FILE" 'capi.database.name')
    UAADB_USERNAME=$(yq read "$DB_VALUES_FILE" 'uaa.database.user')
    UAADB_PASSWORD=$(yq read "$DB_VALUES_FILE" 'uaa.database.password')
    UAADB_NAME=$(yq read "$DB_VALUES_FILE" 'uaa.database.name')
    ...
    ```

## Installation of an internal database

If both, capi and uaa, are configured to use an external database, no internal database will be deployed.

## Example with external RDS database

In the following section, we will show how to setup an AWS RDS database and configure it as the datebase to be used for Cloud Controller and UAA. Please note that the values passed for RDS creation are **not suitable for production environments**.

1. Create a RDS database. The following command will create a small database for development. Please adjust the settings to your requirements.

    ```bash
    export PGPASSWORD=<your password>
    aws rds create-db-instance \
        --engine postgres \
        --db-instance-identifier cf-for-k8s \
        --allocated-storage 20 \
        --db-instance-class db.t2.micro \
        --db-subnet-group default \
        --master-username postgres \
        --master-user-password "$PGPASSWORD" \
        --backup-retention-period 7 \
        --publicly-accessible
    ```

1. Wait until RDS database is ready

    ```bash
    aws rds wait db-instance-available --db-instance-identifier cf-for-k8s
    ```

1. Extract database hostname

    ```bash
    aws rds describe-db-instances --db-instance-identifier cf-for-k8s | jq -r '.DBInstances[0].Endpoint.Address'
    ```

1. Create configuration file `"$DB_VALUES_FILE"`. Please replace the `host`, `password` and `ca_cert` in this file accordingly. You can download the certificate from [here](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html)

    ```yaml
    #@data/values
    ---
    capi:
      #@override/replace
      database:
        adapter: postgres
        host: cf-for-k8s.c4pknugnyzdd.eu-central-1.rds.amazonaws.com
        port: 5432
        user: capi_user
        password: <password for capi_user>
        name: capi_db
        ca_cert: |
          -----BEGIN CERTIFICATE-----
          ...

    uaa:
      #@overlay/replace
      database:
        adapter: postgresql
        host: cf-for-k8s.c4pknugnyzdd.eu-central-1.rds.amazonaws.com
        port: 5432
        user: uaa_user
        password: <password for uaa_user>
        name: uaa_db
        ca_cert: |
          -----BEGIN CERTIFICATE-----
          ...
    ```
1. Set environment variables

    ```bash
    export DB_VALUES_FILE=db-values.yml
    export PGHOST=$(cat "$DB_VALUES_FILE" | yq -r '.capi.database.host' )
    ```

1. Run configuration script from above

    ```bash
    CCDB_USERNAME=...
    ...
    ```

1. [Install cf-for-k8s](../deploy.md)

    i. Configure your [`cf-values.yml`](../deploy.md#cf-values) file.
    i. Render the final K8s template to raw K8s yaml. Pass the `"${DB_VALUES_FILE}"` file as additional file to `ytt`:

    ```bash
    ytt -f config -f "${VALUES_DIR}/cf-values.yml" -f "${DB_VALUES_FILE}" > "${VALUES_DIR}/cf-for-k8s-rendered.yml"
    ```

    i. Install using `kapp`:

    ```bash
    kapp deploy -a cf-for-k8s -f "${VALUES_DIR}/cf-for-k8s-rendered.yml"
    ```
