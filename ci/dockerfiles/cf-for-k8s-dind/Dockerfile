FROM ubuntu:xenial

ENV PACK_VERSION="v0.18.1"
ENV KBLD_VERSION="v0.29.0"
ENV YTT_VERSION="v0.32.0"
ENV VENDIR_VERSION="v0.19.0"

RUN apt-get update
RUN apt-get install -y --no-install-recommends \
  apt-transport-https \
  ca-certificates \
  curl \
  dmsetup \
  git \
  jq \
  openssh-client \
  python3-pip \
  python3-setuptools \
  software-properties-common

RUN pip3 install yq

RUN curl -LO "https://github.com/vmware-tanzu/carvel-kbld/releases/download/${KBLD_VERSION}/kbld-linux-amd64"
RUN mv kbld-linux-amd64 /usr/local/bin/kbld
RUN chmod +x /usr/local/bin/kbld

RUN curl -LO "https://github.com/vmware-tanzu/carvel-ytt/releases/download/${YTT_VERSION}/ytt-linux-amd64"
RUN mv ytt-linux-amd64 /usr/local/bin/ytt
RUN chmod +x /usr/local/bin/ytt

RUN curl -LO "https://github.com/vmware-tanzu/carvel-vendir/releases/download/${VENDIR_VERSION}/vendir-linux-amd64"
RUN mv vendir-linux-amd64 /usr/local/bin/vendir
RUN chmod +x /usr/local/bin/vendir

ADD install-docker.sh /tmp/install-docker.sh
RUN /tmp/install-docker.sh

COPY start-docker.sh /usr/local/bin/start-docker
RUN chmod +x /usr/local/bin/start-docker

RUN curl -LO "https://github.com/buildpacks/pack/releases/download/${PACK_VERSION}/pack-${PACK_VERSION}-linux.tgz"
RUN tar xvf "pack-${PACK_VERSION}-linux.tgz"
RUN mv pack /usr/local/bin/pack
RUN rm "pack-${PACK_VERSION}-linux.tgz"

VOLUME /var/lib/docker
