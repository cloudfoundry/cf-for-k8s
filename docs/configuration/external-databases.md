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

The traffic to an external database will not be encrypted. This will be changed in the near future.

In case of uaa, tls can be enabled by providing `ca_cert`.

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

    ```bash
    VALUES_JSON=$(yaml2json "$VALUES_FILE")
    CCDB_USERNAME=$(jq -r '.capi.database.user' <<< "$VALUES_JSON")
    CCDB_PASSWORD=$(jq -r '.capi.database.password' <<< "$VALUES_JSON")
    CCDB_NAME=$(jq -r '.capi.database.name' <<< "$VALUES_JSON")
    UAADB_USERNAME=$(jq -r '.uaa.database.user' <<< "$VALUES_JSON")
    UAADB_PASSWORD=$(jq -r '.uaa.database.password' <<< "$VALUES_JSON")
    UAADB_NAME=$(jq -r '.uaa.database.name' <<< "$VALUES_JSON")
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


## Example

In the following section, an external database is created using the bitnami postgresql helm chart. Please note that this setup is **not suitable for productive environments**.

1. Install postgresql using helm

    ```bash
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm install postgresql bitnami/postgresql
    ```

1. Create configuration file `db-values.yaml`

    ```yaml
    #@data/values
    ---
    capi:
      database:
        adapter: postgres
        host: postgres-postgresql.default.svc.cluster.local
        port: 5432
        user: capi_user
        password: capi_password
        name: capi_db

    uaa:
      database:
        adapter: postgresql
        host: postgres-postgresql.default.svc.cluster.local
        port: 5432
        user: uaa_user
        password: uaa_password
        name: uaa_db
    ```
1. Set environment variables

    ```bash
    VALUES_FILE=db-values.yaml
    export PGPASSWORD=$(kubectl get secret --namespace default postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)
    export PGHOST=127.0.0.1
    ```
1. Forward port to database

   ```bash
   kubectl port-forward --namespace default svc/postgresql 5432:5432 &
   ```

1. Run configuration script from above

    ```bash
    VALUES_JSON=...
    ...
    ```

1. [Install cf-for-k8s](../deploy.md)

    i. Render the final K8s template to raw K8s configuration. Pass the `db-values.yaml` file as additional file to `ytt`

    ```bash
    ytt -f config -f /tmp/cf-values.yml -f db-values.yaml > /tmp/cf-for-k8s-rendered.yml
    ```

    ii. Install using `kapp`