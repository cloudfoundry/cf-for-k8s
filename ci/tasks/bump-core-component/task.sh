#!/bin/bash -eu

setup_ssh_config() {
  eval $(ssh-agent) >/dev/null 2>&1
  trap "kill $SSH_AGENT_PID" EXIT
  mkdir -p ~/.ssh
  cat > ~/.ssh/config <<EOF
StrictHostKeyChecking no
LogLevel quiet
EOF
  chmod 0600 ~/.ssh/config
}

set_ssh_key() {
  local private_key_path=/tmp/github-private-key
  github_key="${1:-}"

  echo "$github_key" > $private_key_path
  if [ ! -s $private_key_path ]; then
    echo "No github key found" 1>&2
    exit 1
  fi

  chmod 0600 $private_key_path

  ssh-add -D
  SSH_ASKPASS=/bin/false DISPLAY= ssh-add $private_key_path >/dev/null

}


if [[ "${GITHUB_RELEASE}" == "false" ]]; then
  pushd release > /dev/null
    TAG=$(git rev-parse HEAD)
  popd > /dev/null
else
  TAG=$(cat release/tag)
fi

pushd cf-for-k8s-develop > /dev/null
  if [[ "${VENDIR_GITHUB_RELEASE}" == "false" ]]; then
    # we believe we need the component teams to include the necessary files in their release assets
    # before we can switch to using a githubRelease in vendir.yml
    vendir_key="ref"
  else
    vendir_key="tag"
  fi

  CURR_TAG_LINE=$(grep -A 20 "path: .*${REPO_NAME}" vendir.yml | grep ${vendir_key} | head -n1 | awk '{$1=$1;print}')
  sed "s/${CURR_TAG_LINE}/${vendir_key}: ${TAG}/g" vendir.yml > /tmp/vendir.yml && mv /tmp/vendir.yml vendir.yml

  CURR_TAG=$(echo $CURR_TAG_LINE | awk '{print $2}')

  if [[ "${CURR_TAG}" != "${TAG}" ]]; then
    vendir sync

    if [[ -n "${BUILD_DIR}" ]]; then
      pushd "${BUILD_DIR}" > /dev/null
        ./build.sh
      popd > /dev/null
    fi

    git config user.email "${GITHUB_EMAIL}"
    git config user.name "${GITHUB_USER}"
    branch_name=bump/${REPO_NAME}-to-${TAG}

    git checkout -b ${branch_name}
    git add .
    git commit -m "Bump ${REPO_NAME} to ${TAG}"

    setup_ssh_config

    set_ssh_key "${GITHUB_KEY}"
    git push --set-upstream origin ${branch_name}
    hub pull-request -b develop --no-edit
  else
    echo "Tag ${CURR_TAG} has not changed. No update needed."
  fi
popd > /dev/null
