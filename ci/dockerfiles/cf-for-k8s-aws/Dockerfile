FROM google/cloud-sdk:slim

USER root

RUN apt-get update && \
    apt-get install -y git gcc wget curl dnsutils jq zip unzip openssl

RUN wget -O- --tries=3 https://carvel.dev/install.sh | bash

RUN curl -LO --retry 3 --retry-delay 3 https://storage.googleapis.com/kubernetes-release/release/v1.15.7/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

RUN curl -LO --retry 3 --retry-delay 3 https://github.com/cloudfoundry/bosh-cli/releases/download/v6.2.1/bosh-cli-6.2.1-linux-amd64 && \
    chmod +x ./bosh-cli-6.2.1-linux-amd64 && \
    mv ./bosh-cli-6.2.1-linux-amd64 /usr/local/bin/bosh

RUN curl -o awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip && \
    unzip -q awscliv2.zip && \
    ./aws/install -i /usr/local/aws-cli -b /usr/local/bin && \
    aws --version

RUN curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.8/2020-09-18/bin/linux/amd64/aws-iam-authenticator && \
    chmod +x aws-iam-authenticator && \
    mv aws-iam-authenticator /usr/local/bin && \
    aws-iam-authenticator help
