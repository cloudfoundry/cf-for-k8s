FROM cloudfoundry/cflinuxfs3

ENV GO_VERSION 1.15.10

RUN \
      apt update && \
      apt -y install --fix-missing \
            build-essential \
            curl \
            docker \
            git \
            netcat-openbsd \
            htop \
            libpython-dev \
            lsof \
            psmisc \
            python \
            strace \
            libreadline6-dev\
            lsb-core \
            wget \
            unzip \
            libfontconfig1-dev libfreetype6 libssl-dev libpng-dev libjpeg-dev \
            jq \
            libssl-dev \
            libssl1.0.0 \
            libxml2-dev \
            libxslt-dev \
            libyaml-dev \
            openssl \
            vim \
            zip \
            python-pip \
            zlib1g-dev \
      && \
      apt clean

# Temp fix to get around apt-key issues with canonical
RUN chmod 1777 /tmp

# https://kubernetes.io/docs/tasks/tools/install-kubectl/
RUN echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update -y && apt-get install kubectl -y

# Install go
RUN curl "https://storage.googleapis.com/golang/go${GO_VERSION}.linux-amd64.tar.gz" | tar xvz -C /usr/local/

# Add golang environment variables
ENV HOME /root
ENV GOPATH /root/go
ENV PATH "${PATH}:/usr/local/go/bin:/root/bin:${GOPATH}/bin"

# Install ginkgo
RUN go get github.com/onsi/ginkgo/ginkgo

# Install controller-gen for integration tests
RUN	mkdir -p /tmp/controller-gen && \
    cd /tmp/controller-gen && \
    go mod init tmp && \
    go get sigs.k8s.io/controller-tools/cmd/controller-gen@v0.2.4 && \
    rm -rf /tmp/controller-gen

# Install docker
RUN sudo curl -sSL https://get.docker.com/ | sh

# Install k14s
RUN curl -L https://k14s.io/install.sh | bash