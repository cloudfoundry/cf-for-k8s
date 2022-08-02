FROM google/cloud-sdk:alpine

USER root

RUN apk update
RUN apk add \
    build-base \
    jq \
    postgresql-client \
    py3-pip

RUN pip3 install --upgrade pip && pip3 install yq

RUN apk add openssl && \
    curl --retry 3 --retry-delay 3 https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

RUN apk add perl-utils && \
    wget --tries=3 -O- https://carvel.dev/install.sh | bash

RUN echo "Installing kapp" && \
    curl -LO --retry 3 --retry-delay 3 https://github.com/vmware-tanzu/carvel-kapp/releases/download/v0.49.0/kapp-linux-amd64 && \
    chmod +x ./kapp-linux-amd64 && \
    mv kapp-linux-amd64 /usr/local/bin/kapp

RUN echo "Installing ytt" && \
    curl -LO --retry 3 --retry-delay 3 https://github.com/vmware-tanzu/carvel-ytt/releases/download/v0.42.0/ytt-linux-amd64 && \
    chmod +x ./ytt-linux-amd64 && \
    mv ytt-linux-amd64 /usr/local/bin/ytt

RUN echo "Installing kbld" && \
    curl -LO --retry 3 --retry-delay 3 https://github.com/vmware-tanzu/carvel-kbld/releases/download/v0.34.0/kbld-linux-amd64 && \
    chmod +x ./kbld-linux-amd64 && \
    mv kbld-linux-amd64 /usr/local/bin/kbld

RUN echo "Installing vendir" && \
    curl -LO --retry 3 --retry-delay 3 https://github.com/vmware-tanzu/carvel-vendir/releases/download/v0.29.0/vendir-linux-amd64 && \
    chmod +x ./vendir-linux-amd64 && \
    mv vendir-linux-amd64 /usr/local/bin/vendir

# https://kubernetes.io/docs/tasks/tools/install-kubectl/
RUN echo "Installing kubectl" && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x ./kubectl && \
    mv kubectl /usr/local/bin

RUN bosh_cli_version=$(curl --silent "https://api.github.com/repos/cloudfoundry/bosh-cli/releases/latest" | jq -r '.tag_name' | tr -d 'v') && \
    echo "Installing bosh_cli version ${bosh_cli_version}..." && \
    curl -LO --retry 3 --retry-delay 3 https://github.com/cloudfoundry/bosh-cli/releases/download/v${bosh_cli_version}/bosh-cli-${bosh_cli_version}-linux-amd64 && \
    chmod +x ./bosh-cli-${bosh_cli_version}-linux-amd64 && \
    mv ./bosh-cli-${bosh_cli_version}-linux-amd64 /usr/local/bin/bosh

RUN echo "Installing kubeval" && \
    wget --tries=3 https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-linux-amd64.tar.gz && \
    tar xf kubeval-linux-amd64.tar.gz && \
    chmod +x ./kubeval && \
    mv kubeval /usr/local/bin

# For gcloud beta compute ssh/scp
RUN gcloud components install beta -q

# Installing hub (for creating PRs from concourse)
RUN hub_version=$(curl --silent "https://api.github.com/repos/github/hub/releases/latest" | jq -r '.tag_name' | tr -d 'v') && \
    echo "Installing hub version ${hub_version}..." && \
    curl -LO --retry 3 --retry-delay 3 https://github.com/github/hub/releases/download/v${hub_version}/hub-linux-amd64-${hub_version}.tgz && \
    tar xfz hub-linux-amd64-${hub_version}.tgz && \
    chmod +x ./hub-linux-amd64-${hub_version}/bin/hub && \
    mv ./hub-linux-amd64-${hub_version}/bin/hub /usr/local/bin/hub

# ginkgo
RUN export GO_TAR=go1.17.8.linux-amd64.tar.gz && \
    wget --tries=3 https://dl.google.com/go/${GO_TAR} && \
    tar -C /usr/local -xzf ${GO_TAR}

ENV CGO_ENABLED=1

ENV GOPATH /go
ENV PATH=$PATH:/go/bin:/usr/local/go/bin

RUN go install github.com/cloudfoundry/uptimer@latest

# https://github.com/onsi/ginkgo/releases
RUN go install github.com/onsi/ginkgo/ginkgo@latest

# https://github.com/cloudfoundry/cli/releases
WORKDIR /tmp
RUN wget --tries=3 -O cf.tgz "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=v8&source=github" && \
    tar xzvf cf.tgz -C /usr/local/bin && \
    chmod +x /usr/local/bin/cf && \
    /usr/local/bin/cf --version

RUN rm -rf /tmp/*
