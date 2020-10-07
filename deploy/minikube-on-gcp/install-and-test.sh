export HOME=/tmp/minikube
export CGO_ENABLED=0
export GO111MODULE=on
export PATH=/tmp/minikube/bin:/tmp/minikube/go/bin:${PATH}
export KUBECONFIG=/tmp/minikube/.kube/config

function retry {
  local retries=$1
  shift

  local count=0
  until "$@"; do
    exit=$?
    wait=$((2 ** ${count}))
    count=$((${count} + 1))
    if [ ${count} -lt ${retries} ]; then
      echo "Retry ${count}/${retries} exited ${exit}, retrying in ${wait} seconds..."
      sleep ${wait}
    else
      echo "Retry ${count}/${retries} exited ${exit}, no more retries left."
      return ${exit}
    fi
  done
  return 0
}

cd /tmp/minikube/cf-for-k8s
yes | minikube delete
minikube start
CF_VALUES=/tmp/cf-values.yml
CF_RENDERED=/tmp/cf-rendered.yml
ytt -f config -f ${CF_VALUES} > ${CF_RENDERED}
kapp deploy -f ${CF_RENDERED} -a cf -y
retry 7 cf api api.vcap.me --skip-ssl-validation
SMOKE_TEST_API_ENDPOINT="https://api.vcap.me" SMOKE_TEST_APPS_DOMAIN=vcap.me SMOKE_TEST_USERNAME=admin SMOKE_TEST_PASSWORD=$(grep cf_admin_pass ${CF_VALUES} | cut -d" " -f2) SMOKE_TEST_SKIP_SSL=true ./hack/run-smoke-tests.sh
