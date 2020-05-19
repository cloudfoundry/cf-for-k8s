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
```


Please note to the **different spelling** of `postgres`  and `postgresql` for capi and uaa.

As prerequisite, you need to execute the following step inside your postgres installation

```bash
VALUES_FILE=<path to file from above>
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

