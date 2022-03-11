#!/bin/bash -eu

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

CCDB_USERNAME="capi_user"
CCDB_PASSWORD="$(openssl rand -base64 32)"
CCDB_NAME="capi_db"
CCDB_ENCRYPTION_KEY="$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 16 | head -n 1)"

UAADB_USERNAME="uaa_user"
UAADB_PASSWORD="$(openssl rand -base64 32)"
UAADB_NAME="uaa_db"

cat > /tmp/setup_db.sql <<EOT
CREATE DATABASE ${CCDB_NAME};
CREATE ROLE ${CCDB_USERNAME} LOGIN PASSWORD '${CCDB_PASSWORD}';
CREATE DATABASE ${UAADB_NAME};
CREATE ROLE ${UAADB_USERNAME} LOGIN PASSWORD '${UAADB_PASSWORD}';
\c ${CCDB_NAME};
CREATE EXTENSION citext;
\c ${UAADB_NAME};
CREATE EXTENSION citext;
EOT

# shellcheck disable=SC2155
export POSTGRES_PASSWORD=$(kubectl get secret -n external-db postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)
kubectl exec -n external-db statefulset/postgresql -i -- psql "postgresql://postgres:$POSTGRES_PASSWORD@localhost:5432/postgres" < /tmp/setup_db.sql

cat > db-metadata/db-values.yaml <<EOT
#@data/values
---
capi:
  #@overlay/replace
  database:
      adapter: postgres
      host: postgresql.external-db.svc.cluster.local
      port: 5432
      user: $CCDB_USERNAME
      password: $CCDB_PASSWORD
      name: $CCDB_NAME
      ca_cert: ""
      encryption_key: "${CCDB_ENCRYPTION_KEY}"

uaa:
  #@overlay/replace
  database:
      adapter: postgresql
      host: postgresql.external-db.svc.cluster.local
      port: 5432
      user: $UAADB_USERNAME
      password: $UAADB_PASSWORD
      name: $UAADB_NAME
      ca_cert: ""
EOT
