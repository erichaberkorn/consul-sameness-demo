#!/bin/bash
registryPath=$1
consulDir=$2
consulK8sDir=$3

echo "Registry Path: $registryPath"
echo "Consul Directory: $consulDir"
echo "Consul-K8s Directory: $consulK8sDir"

# Build the docker images
make -C $consulDir dev-docker
make -C $consulK8sDir control-plane-dev-docker


# Push and tag the image if the push argument is present
docker tag consul:local "$registryPath"/consul-dev:latest
docker push "$registryPath"/consul-dev:latest

docker tag consul-k8s-control-plane-dev "$registryPath"/consul-k8s-control-plane-dev:latest
docker push "$registryPath"/consul-k8s-control-plane-dev:latest

# Update the values.yaml
CONSUL_SHA=$(docker inspect --format='{{index .RepoDigests 0}}' "$registryPath"/consul-dev:latest)
CONSUL_K8S_SHA=$(docker inspect --format='{{index .RepoDigests 0}}' "$registryPath"/consul-k8s-control-plane-dev:latest)

echo "Consul_SHA: $CONSUL_SHA"
echo "CONSUL_K8S_SHA: $CONSUL_K8S_SHA"

# Update the values.yaml file with the new sha's
yq e -i ".global.image = \"$CONSUL_SHA\"" ../values-ap1.yaml
yq e -i ".global.imageK8S = \"$CONSUL_K8S_SHA\""  ../values-ap1.yaml
yq e -i ".global.image = \"$CONSUL_SHA\"" ../values-ent.yaml
yq e -i ".global.imageK8S = \"$CONSUL_K8S_SHA\""  ../values-ent.yaml