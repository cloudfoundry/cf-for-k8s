FROM google/cloud-sdk:slim

USER root

RUN apt-get update && \
    apt-get install -y git gcc wget curl dnsutils jq google-cloud-sdk
RUN apt-get install -y openssl && \
    curl --retry 3 --retry-delay 3 https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
RUN wget -O- --tries=3 https://carvel.dev/install.sh | bash
RUN curl -LO --retry 3 --retry-delay 3 https://storage.googleapis.com/kubernetes-release/release/v1.15.7/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl
RUN curl -LO --retry 3 --retry-delay 3 https://github.com/cloudfoundry/bosh-cli/releases/download/v6.2.1/bosh-cli-6.2.1-linux-amd64 && \
    chmod +x ./bosh-cli-6.2.1-linux-amd64 && \
    mv ./bosh-cli-6.2.1-linux-amd64 /usr/local/bin/bosh
RUN curl -sL --retry 3 --retry-delay 3 https://aka.ms/InstallAzureCLIDeb | bash
