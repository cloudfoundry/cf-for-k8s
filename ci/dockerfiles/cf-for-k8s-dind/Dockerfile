FROM ubuntu:xenial

ENV PACK_VERSION="v0.18.1"
ENV KBLD_VERSION="v0.29.0"

RUN apt-get update
RUN apt-get install -y --no-install-recommends \
  apt-transport-https \
  ca-certificates \
  curl \
  dmsetup \
  git \
  openssh-client \
  software-properties-common

RUN curl -LO "https://github.com/vmware-tanzu/carvel-kbld/releases/download/${KBLD_VERSION}/kbld-linux-amd64"
RUN mv kbld-linux-amd64 /usr/local/bin/kbld
RUN chmod +x /usr/local/bin/kbld

ADD install-docker.sh /tmp/install-docker.sh
RUN /tmp/install-docker.sh

COPY start-docker.sh /usr/local/bin/start-docker
RUN chmod +x /usr/local/bin/start-docker

RUN curl -LO "https://github.com/buildpacks/pack/releases/download/${PACK_VERSION}/pack-${PACK_VERSION}-linux.tgz"
RUN tar xvf "pack-${PACK_VERSION}-linux.tgz"
RUN mv pack /usr/local/bin/pack
RUN rm "pack-${PACK_VERSION}-linux.tgz"

VOLUME /var/lib/docker
