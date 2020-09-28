FROM curlimages/curl

USER root

# deplab
RUN curl --retry 3 --retry-delay 3 \
    https://github.com/vmware-tanzu/dependency-labeler/releases/download/1.5.0-build.3/deplab-linux-amd64 \
    --output /usr/local/bin/deplab && \
    chmod +x /usr/local/bin/deplab
