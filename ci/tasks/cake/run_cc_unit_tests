#!/usr/bin/env bash
set -e

: ${DB:?}

start_db() {
  if [ "${DB}" = "mysql" ]; then
    # HACK: change access time on mysql files to copy them into the writable layer
    # Context: https://github.com/moby/moby/issues/34390
    find /var/lib/mysql/mysql -exec touch -c -a {} +
    service mysql stop

    mkdir -p /var/lib/ramdisk
    # HACK: not really sure what a good size for the mount is
    mount -t tmpfs -o size=8192m ramdisk /var/lib/ramdisk

    cp -R /var/lib/mysql/* /var/lib/ramdisk/
    chown -R mysql /var/lib/ramdisk
    chgrp -R mysql /var/lib/ramdisk
    chmod 700 /var/lib/ramdisk

    # HACKish: update mysql config to use ramdisk mount to back its disk storage
    echo -e "\n[mysqld]\ndatadir = /var/lib/ramdisk" >> /etc/mysql/my.cnf

    service mysql restart
    trap stop_mysql EXIT
  elif [ "${DB}" = "postgres" ]; then
    service postgresql start
    POSTGRES_DATA_DIR=$(su postgres -c "psql -c 'show data_directory'" | grep main)
    POSTGRES_CONF_FILE=$(su postgres -c "psql -c 'show config_file'" | grep "postgresql.conf")
    
    service postgresql stop

    mkdir -p /var/lib/ramdisk
    # HACK: not really sure what a good size for the mount is
    mount -t tmpfs -o size=8192m ramdisk /var/lib/ramdisk

    
    cp -R $POSTGRES_DATA_DIR/* /var/lib/ramdisk/
    chown -R postgres /var/lib/ramdisk
    chgrp -R postgres /var/lib/ramdisk
    chmod 700 /var/lib/ramdisk

    # HACKish: update postgres config to use ramdisk mount to back its disk storage
    sed -i -E "s#data_directory = (.*)#data_directory = '/var/lib/ramdisk'#g" $POSTGRES_CONF_FILE

    service postgresql restart
    trap stop_postgres EXIT
  elif [ "${DB}" = "mssql" ]; then
    service docker start
    sleep 5
    service docker stop
    dockerd --data-root /scratch/docker ${server_args} >/tmp/docker.log 2>&1 &
    echo $! > /tmp/docker.pid

    trap stop_docker EXIT
    sleep 5

    LOG_FILE="/tmp/mssql.log" ./scripts/run-ms-sql-background.sh
  else
    echo "Unknown DB type '${DB}', this script only supports 'mysql', 'postgres', and 'mssql'"
    exit 1
  fi
}

stop_mysql() {
  service mysql stop
}

stop_postgres() {
  service postgresql stop
}

stop_docker() {
  local pid=$(cat /tmp/docker.pid)
  if [ -z "$pid" ]; then
    return 0
  fi

  kill -TERM $pid
  wait $pid
}

pushd cloud_controller_ng > /dev/null
  start_db

  export BUNDLE_GEMFILE=Gemfile
  bundle install

  if [ -n "${RUN_IN_PARALLEL}" ]; then
    rubocop --parallel
    bundle exec rake spec:all
  else
    rubocop
    bundle exec rake spec:serial
  fi
popd > /dev/null
