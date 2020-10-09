# Deploy from a private registry

1. Relocate all system images into your private registry:

  ```console
  PRIVATE_REGISTRY_HOSTNAME=<your-private-registry> # "index.docker.io" for example, if using a private Dockerhub account

  ytt -f config -f ${TMP_DIR}/cf-values.yml | kbld -f - --lock-output ${TMP_DIR}/cf-for-k8s-images.tmp
  kbld relocate -f ${TMP_DIR}/cf-for-k8s-images.tmp --repository ${PRIVATE_REGISTRY_HOSTNAME}/cf-for-k8s --lock-output ${TMP_DIR}/cf-for-k8s-relocated-images.yml
  ```

2. If your Kubernetes Nodes are not already configured and able to pull images from the private registry, you will need to configure its credentials in your cf-values.yml to add image-pull-secrets

  ```console
  cat >>${TMP_DIR}/cf-values.yml <<EOF
  system_registry:
    add_image_pull_secrets: true
    hostname: <private-registry-hostname> # example: index.docker.io
    username: <private-registry-username>
    password: <private-registry-password>
  EOF
  ```

3. Rerender the final K8s template with relocated images to raw K8s configuration

  ```console
  ytt -f config -f ${TMP_DIR}/cf-values.yml | kbld -f - -f ${TMP_DIR}/cf-for-k8s-relocated-images.yml > ${TMP_DIR}/cf-for-k8s-rendered.yml
  ```

4. Install using `kapp` and pass the above K8s configuration file

  ```console
  kapp deploy -a cf -f ${TMP_DIR}/cf-for-k8s-rendered.yml -y
  ```
