FROM bash:latest

# deplab
RUN latest_deplab_version=$(curl --silent "https://api.github.com/repos/vmware-tanzu/dependency-labeler/releases/latest" | jq -r '.tag_name') && \
    echo "Installing deplab version ${latest_deplab_version}..." && \
    wget https://github.com/vmware-tanzu/dependency-labeler/releases/download/${latest_deplab_version}/deplab-linux-amd64 \
    -O /usr/local/bin/deplab && \
    chmod +x /usr/local/bin/deplab
