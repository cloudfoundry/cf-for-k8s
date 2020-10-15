#!/bin/bash -eu

function setup_gke {
    source cf-for-k8s-ci/ci/helpers/gke.sh

    if [[ -d pool-lock ]]; then
    if [[ -d tf-vars ]]; then
        echo "You may not specify both pool-lock and tf-vars"
        exit 1
    fi
    cluster_name="$(cat pool-lock/name)"
    elif [[ -d tf-vars ]]; then
    if [[ -d terraform ]]; then
        cluster_name="$(cat tf-vars/env-name.txt)"
    else
        echo "You must provide both tf-vars and terraform inputs together"
        exit 1
    fi
    else
    echo "You must provide either pool-lock or tf-vars"
    exit 1
    fi

    gcloud_auth "${cluster_name}"

    kubectl create namespace external-db
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm install -n external-db --wait postgresql bitnami/postgresql

}

function setup_db {
    RDS_SUFFIX="$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 16 | head -n 1)"
    CCDB_USERNAME="capi_user_$RDS_SUFFIX"
    CCDB_PASSWORD="$(openssl rand -base64 32)"
    CCDB_NAME="capi_db_$RDS_SUFFIX"
    CCDB_ENCRYPTION_KEY="$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 16 | head -n 1)"

    UAADB_USERNAME="uaa_user_$RDS_SUFFIX"
    UAADB_PASSWORD="$(openssl rand -base64 32)"
    UAADB_NAME="uaa_db_$RDS_SUFFIX"

    cat > /tmp/setup_db.sql <<EOT
    CREATE DATABASE "${CCDB_NAME}";
    CREATE ROLE ${CCDB_USERNAME} LOGIN PASSWORD '${CCDB_PASSWORD}';
    CREATE DATABASE "${UAADB_NAME}";
    CREATE ROLE ${UAADB_USERNAME} LOGIN PASSWORD '${UAADB_PASSWORD}';
    \c "${CCDB_NAME}";
    CREATE EXTENSION citext;
    \c "${UAADB_NAME}";
    CREATE EXTENSION citext;
EOT

    echo "Initializing RDS database ..."
    export PGHOST=$(jq -r '.address' terraform-rds/metadata)
    psql -U postgres -f /tmp/setup_db.sql

    cat > db-metadata/db-values.yaml <<EOT
#@data/values
---
capi:
    #@overlay/replace
    database:
        adapter: postgres
        host: $PGHOST
        port: 5432
        user: $CCDB_USERNAME
        password: $CCDB_PASSWORD
        name: $CCDB_NAME
        ca_cert: |
            -----BEGIN CERTIFICATE-----
            MIIEBjCCAu6gAwIBAgIJAMc0ZzaSUK51MA0GCSqGSIb3DQEBCwUAMIGPMQswCQYD
            VQQGEwJVUzEQMA4GA1UEBwwHU2VhdHRsZTETMBEGA1UECAwKV2FzaGluZ3RvbjEi
            MCAGA1UECgwZQW1hem9uIFdlYiBTZXJ2aWNlcywgSW5jLjETMBEGA1UECwwKQW1h
            em9uIFJEUzEgMB4GA1UEAwwXQW1hem9uIFJEUyBSb290IDIwMTkgQ0EwHhcNMTkw
            ODIyMTcwODUwWhcNMjQwODIyMTcwODUwWjCBjzELMAkGA1UEBhMCVVMxEDAOBgNV
            BAcMB1NlYXR0bGUxEzARBgNVBAgMCldhc2hpbmd0b24xIjAgBgNVBAoMGUFtYXpv
            biBXZWIgU2VydmljZXMsIEluYy4xEzARBgNVBAsMCkFtYXpvbiBSRFMxIDAeBgNV
            BAMMF0FtYXpvbiBSRFMgUm9vdCAyMDE5IENBMIIBIjANBgkqhkiG9w0BAQEFAAOC
            AQ8AMIIBCgKCAQEArXnF/E6/Qh+ku3hQTSKPMhQQlCpoWvnIthzX6MK3p5a0eXKZ
            oWIjYcNNG6UwJjp4fUXl6glp53Jobn+tWNX88dNH2n8DVbppSwScVE2LpuL+94vY
            0EYE/XxN7svKea8YvlrqkUBKyxLxTjh+U/KrGOaHxz9v0l6ZNlDbuaZw3qIWdD/I
            6aNbGeRUVtpM6P+bWIoxVl/caQylQS6CEYUk+CpVyJSkopwJlzXT07tMoDL5WgX9
            O08KVgDNz9qP/IGtAcRduRcNioH3E9v981QO1zt/Gpb2f8NqAjUUCUZzOnij6mx9
            McZ+9cWX88CRzR0vQODWuZscgI08NvM69Fn2SQIDAQABo2MwYTAOBgNVHQ8BAf8E
            BAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUc19g2LzLA5j0Kxc0LjZa
            pmD/vB8wHwYDVR0jBBgwFoAUc19g2LzLA5j0Kxc0LjZapmD/vB8wDQYJKoZIhvcN
            AQELBQADggEBAHAG7WTmyjzPRIM85rVj+fWHsLIvqpw6DObIjMWokpliCeMINZFV
            ynfgBKsf1ExwbvJNzYFXW6dihnguDG9VMPpi2up/ctQTN8tm9nDKOy08uNZoofMc
            NUZxKCEkVKZv+IL4oHoeayt8egtv3ujJM6V14AstMQ6SwvwvA93EP/Ug2e4WAXHu
            cbI1NAbUgVDqp+DRdfvZkgYKryjTWd/0+1fS8X1bBZVWzl7eirNVnHbSH2ZDpNuY
            0SBd8dj5F6ld3t58ydZbrTHze7JJOd8ijySAp4/kiu9UfZWuTPABzDa/DSdz9Dk/
            zPW4CXXvhLmE02TA9/HeCw3KEHIwicNuEfw=
            -----END CERTIFICATE-----
        encryption_key: "${CCDB_ENCRYPTION_KEY}"
uaa:
    #@overlay/replace
    database:
        adapter: postgresql
        host: $PGHOST
        port: 5432
        user: $UAADB_USERNAME
        password: $UAADB_PASSWORD
        name: $UAADB_NAME
        ca_cert: |
            -----BEGIN CERTIFICATE-----
            MIIEBjCCAu6gAwIBAgIJAMc0ZzaSUK51MA0GCSqGSIb3DQEBCwUAMIGPMQswCQYD
            VQQGEwJVUzEQMA4GA1UEBwwHU2VhdHRsZTETMBEGA1UECAwKV2FzaGluZ3RvbjEi
            MCAGA1UECgwZQW1hem9uIFdlYiBTZXJ2aWNlcywgSW5jLjETMBEGA1UECwwKQW1h
            em9uIFJEUzEgMB4GA1UEAwwXQW1hem9uIFJEUyBSb290IDIwMTkgQ0EwHhcNMTkw
            ODIyMTcwODUwWhcNMjQwODIyMTcwODUwWjCBjzELMAkGA1UEBhMCVVMxEDAOBgNV
            BAcMB1NlYXR0bGUxEzARBgNVBAgMCldhc2hpbmd0b24xIjAgBgNVBAoMGUFtYXpv
            biBXZWIgU2VydmljZXMsIEluYy4xEzARBgNVBAsMCkFtYXpvbiBSRFMxIDAeBgNV
            BAMMF0FtYXpvbiBSRFMgUm9vdCAyMDE5IENBMIIBIjANBgkqhkiG9w0BAQEFAAOC
            AQ8AMIIBCgKCAQEArXnF/E6/Qh+ku3hQTSKPMhQQlCpoWvnIthzX6MK3p5a0eXKZ
            oWIjYcNNG6UwJjp4fUXl6glp53Jobn+tWNX88dNH2n8DVbppSwScVE2LpuL+94vY
            0EYE/XxN7svKea8YvlrqkUBKyxLxTjh+U/KrGOaHxz9v0l6ZNlDbuaZw3qIWdD/I
            6aNbGeRUVtpM6P+bWIoxVl/caQylQS6CEYUk+CpVyJSkopwJlzXT07tMoDL5WgX9
            O08KVgDNz9qP/IGtAcRduRcNioH3E9v981QO1zt/Gpb2f8NqAjUUCUZzOnij6mx9
            McZ+9cWX88CRzR0vQODWuZscgI08NvM69Fn2SQIDAQABo2MwYTAOBgNVHQ8BAf8E
            BAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUc19g2LzLA5j0Kxc0LjZa
            pmD/vB8wHwYDVR0jBBgwFoAUc19g2LzLA5j0Kxc0LjZapmD/vB8wDQYJKoZIhvcN
            AQELBQADggEBAHAG7WTmyjzPRIM85rVj+fWHsLIvqpw6DObIjMWokpliCeMINZFV
            ynfgBKsf1ExwbvJNzYFXW6dihnguDG9VMPpi2up/ctQTN8tm9nDKOy08uNZoofMc
            NUZxKCEkVKZv+IL4oHoeayt8egtv3ujJM6V14AstMQ6SwvwvA93EP/Ug2e4WAXHu
            cbI1NAbUgVDqp+DRdfvZkgYKryjTWd/0+1fS8X1bBZVWzl7eirNVnHbSH2ZDpNuY
            0SBd8dj5F6ld3t58ydZbrTHze7JJOd8ijySAp4/kiu9UfZWuTPABzDa/DSdz9Dk/
            zPW4CXXvhLmE02TA9/HeCw3KEHIwicNuEfw=
            -----END CERTIFICATE-----
EOT
}

if [[ -n $GCP_SERVICE_ACCOUNT_JSON ]] ;then
    echo "Preparing GCP credentials ..."
    setup_gke
fi

echo "Starting database setup ..."
setup_db
echo "Finished database setup."
