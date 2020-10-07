#!/bin/bash
set -eu

function setup_external_db {
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
}

function read_db_values {
  DB_VALUES=$(cat db-metadata/db-values.yaml)
  CAPI_HOST=$(yq -r '.capi.database.host' <<< "$DB_VALUES")
  CAPI_PORT=$(yq -r '.capi.database.port' <<< "$DB_VALUES")
  CAPI_NAME=$(yq -r '.capi.database.name' <<< "$DB_VALUES")

  UAA_HOST=$(yq -r '.uaa.database.host' <<< "$DB_VALUES")
  UAA_PORT=$(yq -r '.uaa.database.port' <<< "$DB_VALUES")
  UAA_NAME=$(yq -r '.uaa.database.name' <<< "$DB_VALUES")
}

read_db_values

if [ ${EXTERNAL_DB} == "rds" ];then
  CAPI_TABLE_COUNT=$(psql --host="$CAPI_HOST" --port="$CAPI_PORT" --username="postgres" "$CAPI_NAME" -c "select count(*) from information_schema.tables where table_schema='public';" -qtAX)
  UAA_TABLE_COUNT=$(psql --host="$UAA_HOST" --port="$UAA_PORT" --username="postgres" "$UAA_NAME" -c "select count(*) from information_schema.tables where table_schema='public';" -qtAX)
elif [ ${EXTERNAL_DB} == "incluster" ];then
  setup_external_db
  # shellcheck disable=SC2155
  export PGPASSWORD=$(kubectl get secret -n external-db postgresql -o jsonpath="{.data.postgresql-password}" | base64 -d)
  CAPI_TABLE_COUNT=$(kubectl exec -n external-db statefulset/postgresql-postgresql -i -- psql "postgresql://postgres:$PGPASSWORD@localhost:$CAPI_PORT/$CAPI_NAME" -c "select count(*) from information_schema.tables where table_schema='public';" -qtAX)
  UAA_TABLE_COUNT=$(kubectl exec -n external-db statefulset/postgresql-postgresql -i -- psql "postgresql://postgres:$PGPASSWORD@localhost:$UAA_PORT/$UAA_NAME" -c "select count(*) from information_schema.tables where table_schema='public';" -qtAX)
else
  echo "You need to specifiy an EXTERNAL_DB"
  exit 1
fi

echo "Checking if tables exist in database $CAPI_NAME on $CAPI_HOST"
if [ ! ${CAPI_TABLE_COUNT} -gt 0 ];then
    echo "No tables found in $CAPI_NAME"
    exit 1
fi

echo "Checking if tables exist in database $UAA_NAME on $CAPI_HOST"
if [ ! ${UAA_TABLE_COUNT} -gt 0 ];then
    echo "No tables found in $UAA_NAME"
    exit 1
fi

echo "Check successfully completed."
