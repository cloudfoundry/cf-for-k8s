#!/bin/bash

set -u

pushd cf-for-k8s-ci >> /dev/null
  FAIL=false

  for task_file in ci/tasks/*/task.yml; do
      ack "$task_file" ./ci >> /dev/null
      if [[ $? != 0 ]]; then
        FAIL=true
        echo "$task_file is not used in any pipeline"
      fi

  done

  if $FAIL; then
    exit 1
  fi
popd >> /dev/null
