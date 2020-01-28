# UAA k8s release

Exploring what this might look like.

## Random things I learned yesterday while hacking around

### Getting started with minikube

https://medium.com/@yzhong.cs/developing-microservices-with-minikube-81b31e5366ac
> eval $(minikube docker-env)

https://github.com/kubernetes/minikube/issues/1568
> minikube ssh
> sudo ip link set docker0 promisc on

### Setting up the buildpack

UAA modifies server.xml and I dunno how to get those changes into the official tomcat buildpack. So, I forked it!

1. clone this http://github.com/shamus/tomcat-cnb
2. execute `./scripts/build.sh`

### Building the image

I set up a git submodule to point at the uaa in this repo a la uaa-release.
To build the image
> git submodule update --init
> cd src/uaa
> gradlew clean assemble
> cd uaa/build/libs
> pack build --builder cloudfoundry/cnb:cflinuxfs3 --buildpack org.cloudfoundry.archiveexpanding --buildpack org.cloudfoundry.openjdk --buildpack org.cloudfoundry.jvmapplication --buildpack ~/go/src/github.com/shamus/tomcat-cnb uaa

Then check that the image showed up in docker

> docker images | grep uaa

### Chart stuff
> helm template --values values.yaml --output-dir ./manifests .

### Have k8s run it
> kubectl apply --recursive --filename ./manifests/uaa-k8srelease/

### Testing stuff
can I hit my service from within the cluster?
> kubectl exec -it <pod id> curl <cluster ip>:<service port>

### Beyond 

We'll definitely have to fork the tomcat buildpack and we modify
server.xml

Also we can use init containers and take a cue from openshift for cert
management:

https://developers.redhat.com/blog/2017/11/22/dynamically-creating-java-keystores-openshift/
https://kubernetes.io/docs/concepts/workloads/pods/init-containers/

