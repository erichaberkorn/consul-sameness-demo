CHART_DIR=~/dev/consul-k8s/charts/consul
#CHART_DIR = hashicorp/consul
REGISTRY_PORT=5002
#REGISTRY_PATH=localhost:5002
REGISTRY_PATH=k3d-registry.localhost:5002
CONSUL_DIR=~/dev/consul-enterprise
CONSUL_K8S_DIR=~/dev/consul-k8s


# image builds and pushes the Consul and Consul-K8s images to the registry. It also updates the helm value files with the correct image SHAs
image:
	@cd image-create; ./build-and-push-enterprise.sh $(REGISTRY_PATH) $(CONSUL_DIR) $(CONSUL_K8S_DIR)

# registry creates the k3d registry
registry:
	k3d registry create -p $(REGISTRY_PORT) registry.localhost

# registry-delete deletes the k3d registry
registry-delete:
	k3d registry delete registry.localhost

# setup batches the registry and image creation so that we can run the install
setup: registry image

# install will reset all the clusters and install Consul/perform all the necessary sameness setup
install:
	./reset-clusters.sh $(REGISTRY_PORT); \
 	./install-consul.sh $(CHART_DIR); \
 	./configure_k8s.sh; \
 	./sameness-sync.sh; \

# uninstall deletes all of the clusters
uninstall:
	k3d cluster delete c1; \
    k3d cluster delete c2; \
    k3d cluster delete c3; \
    k3d cluster delete c4; \

get-bootstrap-token:
	kubectl get secret --context k3d-c1 --namespace consul consul-bootstrap-acl-token -o yaml

# teardown deletes the registry and deletes all the clusters
teardown: registry-delete uninstall

.PHONY: image setup registry registry-delete setup install uninstall teardown get-bootstrap-token