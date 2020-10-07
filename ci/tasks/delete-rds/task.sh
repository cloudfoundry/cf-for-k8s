#!/bin/bash -eu


if [[ -f db-metadata/db-values.yaml ]];then
    export PGHOST=$(jq -r '.address' terraform-rds/metadata)

    CCDB_USERNAME="$(yq -r '.capi.database.user' db-metadata/db-values.yaml)"
    CCDB_NAME="$(yq -r '.capi.database.name' db-metadata/db-values.yaml)"

    UAADB_USERNAME="$(yq -r '.uaa.database.user' db-metadata/db-values.yaml)"
    UAADB_NAME="$(yq -r '.uaa.database.name' db-metadata/db-values.yaml)"

    cat > /tmp/setup_db.sql <<EOT
    SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${CCDB_NAME}';

    DROP DATABASE IF EXISTS "${CCDB_NAME}";
    DROP ROLE IF EXISTS "${CCDB_USERNAME}";

    SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${UAADB_NAME}';
    DROP DATABASE IF EXISTS "${UAADB_NAME}";
    DROP ROLE IF EXISTS "${UAADB_USERNAME}";
EOT

    echo "Deleting role $CCDB_USERNAME and database $CCDB_NAME"
    echo "Deleting role $UAADB_USERNAME and database $UAADB_NAME"

    psql -U postgres -f /tmp/setup_db.sql
fi
