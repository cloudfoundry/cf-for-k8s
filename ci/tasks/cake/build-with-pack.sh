#!/bin/bash

set -eu

# Stole this from BOSH team: https://github.com/cloudfoundry/bosh/blob/master/ci/old-docker/main-bosh-docker/start-bosh.sh
# Their script had more complexity as they were using this as a docker cpi.
# We only need a simple docker running.

function sanitize_cgroups() {
  mkdir -p /sys/fs/cgroup
  mountpoint -q /sys/fs/cgroup || \
    mount -t tmpfs -o uid=0,gid=0,mode=0755 cgroup /sys/fs/cgroup

  mount -o remount,rw /sys/fs/cgroup

  sed -e 1d /proc/cgroups | while read sys hierarchy num enabled; do
    if [ "$enabled" != "1" ]; then
      # subsystem disabled; skip
      continue
    fi

    grouping="$(cat /proc/self/cgroup | cut -d: -f2 | grep "\\<$sys\\>")"
    if [ -z "$grouping" ]; then
      # subsystem not mounted anywhere; mount it on its own
      grouping="$sys"
    fi

    mountpoint="/sys/fs/cgroup/$grouping"

    mkdir -p "$mountpoint"

    # clear out existing mount to make sure new one is read-write
    if mountpoint -q "$mountpoint"; then
      umount "$mountpoint"
    fi

    mount -n -t cgroup -o "$grouping" cgroup "$mountpoint"

    if [ "$grouping" != "$sys" ]; then
      if [ -L "/sys/fs/cgroup/$sys" ]; then
        rm "/sys/fs/cgroup/$sys"
      fi

      ln -s "$mountpoint" "/sys/fs/cgroup/$sys"
    fi
  done
}

function start_docker() {
  sanitize_cgroups

  # ensure systemd cgroup is present
  mkdir -p /sys/fs/cgroup/systemd
  if ! mountpoint -q /sys/fs/cgroup/systemd ; then
    mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd
  fi

  # check for /proc/sys being mounted readonly, as systemd does
  if grep '/proc/sys\s\+\w\+\s\+ro,' /proc/mounts >/dev/null; then
    mount -o remount,rw /proc/sys
  fi

  trap stop_docker EXIT
  service docker start

  rc=1
  for i in $(seq 1 100); do
    echo waiting for docker to come up...
    sleep 1
    set +e
    docker info 1>/dev/null 2>&1
    rc=$?
    set -e
    if [ "$rc" -eq "0" ]; then
        break
    fi
  done

  if [ "$rc" -ne "0" ]; then
    exit 1
  fi
}

function stop_docker() {
  service docker stop
}

start_docker

# parameterizing this is hard in place - ADDITIONAL_ARGS is a hack
pack build built-image --builder paketobuildpacks/builder:full --path "source-repository/${CONTEXT_PATH}" ${ADDITIONAL_ARGS}

docker save built-image -o image/image.tar

