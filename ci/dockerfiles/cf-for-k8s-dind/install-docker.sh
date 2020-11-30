#!/bin/bash

set -eu -o pipefail

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get update

apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io

rm -rf /var/lib/apt/lists/*
