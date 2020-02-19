FROM ubuntu:bionic

RUN apt-get update && \
    apt-get install -y git gcc wget

RUN export GO_TAR=go1.13.8.linux-amd64.tar.gz && \
    wget https://dl.google.com/go/${GO_TAR} && \
    tar -C /usr/local -xzf ${GO_TAR}

ENV PATH=$PATH:/usr/local/go/bin:/root/go/bin
# https://github.com/golang/go/issues/28065
ENV CGO_ENABLED=0
# https://golang.org/doc/go1.13#modules
ENV GO111MODULE=on

# https://github.com/onsi/ginkgo/releases
RUN go get -u github.com/onsi/ginkgo/ginkgo@v1.11.0

# https://github.com/cloudfoundry/cli/releases
WORKDIR /tmp
RUN \
  wget -O "cf-tar" "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=6.49.0" && \
  tar xzvf cf-tar -C /usr/local/bin && \
  chmod +x /usr/local/bin/cf && \
  wget https://github.com/cloudfoundry/log-cache-cli/releases/download/v2.1.0/log-cache-cf-plugin-linux && \
  cf install-plugin -f log-cache-cf-plugin-linux

RUN rm -rf /tmp/*

RUN go version && \
    ginkgo version && \
    cf --version && \
    cf tail --help
