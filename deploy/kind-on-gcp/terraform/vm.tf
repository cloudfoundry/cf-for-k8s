// Terraform plugin for creating random IDs
resource "random_id" "instance_id" {
  byte_length = 8
}

// Allow SSH access to the VM
resource "google_compute_firewall" "default" {
  name    = "kind-vm-${random_id.instance_id.hex}-firewall"
  network = google_compute_network.default.name

  source_ranges = [ "0.0.0.0/0" ]

  allow {
    protocol = "tcp"
    ports = ["22"]
  }
}

resource "google_compute_network" "default" {
  name = "kind-vm-${random_id.instance_id.hex}-network"
}

resource "tls_private_key" "default" {
  algorithm = "RSA"
}

// A single Google Cloud Engine instance
resource "google_compute_instance" "default" {
  name         = "kind-vm-${random_id.instance_id.hex}"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      size = 100
      image = "cos-cloud/cos-stable"
    }
  }

  network_interface {
    network = google_compute_network.default.self_link

    access_config {
      // Include this section to give the VM an external ip address
    }
  }

  metadata = {
    ssh_keys = "tester:${tls_private_key.default.public_key_openssh}"
  }

  metadata_startup_script = <<EOT
echo "Remounting /tmp to allow executables..."
mount -o remount,rw,nosuid,nodev,exec /tmp

echo "Preparing workspace..."
export HOME=/tmp/kind
mkdir -p $HOME/bin
export PATH=$HOME/bin:$PATH

function retry {
  local retries=$1
  shift

  local count=0
  until "$@"; do
    exit=$?
    wait=$((2 ** $count))
    count=$(($count + 1))
    if [ $count -lt $retries ]; then
      echo "Retry $count/$retries exited $exit, retrying in $wait seconds..."
      sleep $wait
    else
      echo "Retry $count/$retries exited $exit, no more retries left."
      return $exit
    fi
  done
  return 0
}

cd $HOME/bin
  echo "Creating shasum script..."
  cat <<EOF > shasum
if [ "$1" = "-v" ]; then
sha256sum --version
else
sha256sum $@
fi
EOF
  chmod +x shasum
  shasum -v

  echo "Installing jq..."
  retry 5 curl -Lo ./jq "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
  chmod +x jq
  jq --version

  echo "Installing kind..."
  KIND_VERSION=$(curl --silent https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | jq -r .tag_name)
  retry 5 curl -Lo ./kind "https://github.com/kubernetes-sigs/kind/releases/download/$KIND_VERSION/kind-linux-amd64"
  chmod +x kind
  kind --version

  echo "Installing CF CLI..."
  retry 5 curl -Lo ./cf.tgz "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=v7&source=github"
  tar xf cf.tgz cf cf7
  rm cf.tgz
  cf --version

  echo "Installing Carvel tools..."
  function install_carvel_tools {
      curl -L "https://carvel.dev/install.sh" | K14SIO_INSTALL_BIN_DIR=/tmp/kind/bin PATH=/tmp/kind/bin:$PATH bash
  }
  retry 5 install_carvel_tools
  ytt version
  kapp version
cd -

cd $HOME
  echo "Installing Go..."
  retry 5 curl -Lo ./go.tgz "https://dl.google.com/go/go1.13.8.linux-amd64.tar.gz"
  tar xf go.tgz
  export PATH=$HOME/go/bin:$PATH
  export CGO_ENABLED=0
  export GO111MODULE=on
  go version

  echo "Installing Ginkgo..."
  retry 5 go get -u "github.com/onsi/ginkgo/ginkgo@v1.14.2"
  ginkgo version

  echo "Change ownership of $HOME to tester..."
  chown -R tester .
cd -

EOT
}
