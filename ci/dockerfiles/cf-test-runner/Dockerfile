# https://hub.docker.com/_/golang/?tab=tags&page=1&name=alpine
FROM golang:alpine3.11

RUN apk update
# https://pkgs.alpinelinux.org/packages?name=git
RUN apk add git=2.24.1-r0
# https://pkgs.alpinelinux.org/packages?name=gcc
RUN apk add gcc=9.2.0-r3

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
  chmod +x /usr/local/bin/cf

RUN rm -rf /tmp/*
