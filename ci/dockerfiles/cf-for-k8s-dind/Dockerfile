FROM ubuntu:xenial

RUN apt-get update
RUN apt-get install -y --no-install-recommends \
  apt-transport-https \
  ca-certificates \
  curl \
  git \
  openssh-client \
  software-properties-common

ADD install-docker.sh /tmp/install-docker.sh
RUN /tmp/install-docker.sh

COPY start-docker.sh /usr/local/bin/start-docker
RUN chmod +x /usr/local/bin/start-docker

VOLUME /var/lib/docker
