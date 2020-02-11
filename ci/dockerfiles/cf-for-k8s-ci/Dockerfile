FROM google/cloud-sdk:278.0.0-alpine

RUN apk update
RUN apk add openssl && \
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
RUN apk add perl-utils && \
    wget -O- https://k14s.io/install.sh | bash
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.15.7/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl
RUN curl -LO https://github.com/cloudfoundry/bosh-cli/releases/download/v6.2.1/bosh-cli-6.2.1-linux-amd64 && \
    chmod +x ./bosh-cli-6.2.1-linux-amd64 && \
    mv ./bosh-cli-6.2.1-linux-amd64 /usr/local/bin/bosh
RUN apk add jq=1.6-r0
