# System Registry Management

## Host system images in a specified registry

As an operator, you may want to deploy cf-for-k8s with system images hosted in your own repository. (For instance, to guarantee image availability or to manage Dockerhub rate limiting.) To do so, you can leverage `kbld` for image relocation and the system_registry data values to pass your credentials as imagePullSecrets. Note that for TLS communication, you will need to use a publicly trusted repository.

1. Relocate all system images into your private registry and generate a relocated-images file:

  ```console
  TMP_DIR=<your-tmp-dir-path> ; mkdir -p ${TMP_DIR}
  PRIVATE_REGISTRY_HOSTNAME=<your-private-registry>  # "index.docker.io/<docker-user-or-org>" for example, if using Dockerhub

  ytt -f config -f ${TMP_DIR}/cf-values.yml | kbld -f - --lock-output ${TMP_DIR}/cf-for-k8s-images.tmp
  kbld relocate -f ${TMP_DIR}/cf-for-k8s-images.tmp --repository ${PRIVATE_REGISTRY_HOSTNAME}/cf-for-k8s --lock-output ${TMP_DIR}/cf-for-k8s-relocated-images.yml
  ```

2. If your Kubernetes Nodes are not already configured and able to pull images from the private registry, you will need to configure their credentials in your cf-values.yml to add image-pull-secrets

  ```console
  cat >>${TMP_DIR}/cf-values.yml <<EOF
  system_registry:
    add_image_pull_secrets: true
    hostname: <registry-hostname>  #! example: index.docker.io/<docker-user-or-org>
    username: <registry-username>
    password: <registry-password>
  EOF
  ```

3. Render the final K8s template using `ytt` with the relocated-images file

  ```console
  ytt -f config -f ${TMP_DIR}/cf-values.yml | kbld -f - -f ${TMP_DIR}/cf-for-k8s-relocated-images.yml > ${TMP_DIR}/cf-for-k8s-rendered.yml
  ```

4. Install using `kapp`, providing the rendered `cf-for-k8s` yaml

  ```console
  kapp deploy -a cf -f ${TMP_DIR}/cf-for-k8s-rendered.yml -y
  ```
