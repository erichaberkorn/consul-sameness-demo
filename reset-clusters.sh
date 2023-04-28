# k3d registry create -p 5000 registry.localhost
# make dev-docker && docker tag consul-dev k3d-registry.localhost:5000/consul-dev && docker push k3d-registry.localhost:5000/consul-dev
# https://docs.docker.com/registry/insecure/

k3d cluster delete c1
k3d cluster delete c2
k3d cluster delete c3
k3d cluster delete c4
sleep 1
k3d cluster create c1 --registry-use k3d-registry.localhost:5001
sleep 1
k3d cluster create c2 --registry-use k3d-registry.localhost:5001
sleep 1
k3d cluster create c3 --registry-use k3d-registry.localhost:5001
sleep 1
k3d cluster create c4 --registry-use k3d-registry.localhost:5001

docker network connect k3d-c1 k3d-c2-server-0
docker network connect k3d-c2 k3d-c1-server-0

docker network connect k3d-c1 k3d-c3-server-0
docker network connect k3d-c3 k3d-c1-server-0

docker network connect k3d-c1 k3d-c4-server-0
docker network connect k3d-c4 k3d-c1-server-0

docker network connect k3d-c2 k3d-c3-server-0
docker network connect k3d-c3 k3d-c2-server-0

docker network connect k3d-c2 k3d-c4-server-0
docker network connect k3d-c4 k3d-c2-server-0

docker network connect k3d-c3 k3d-c4-server-0
docker network connect k3d-c4 k3d-c3-server-0

kubectl --context k3d-c1 label node k3d-c1-server-0 topology.kubernetes.io/region="us-east-1"
kubectl --context k3d-c3 label node k3d-c3-server-0 topology.kubernetes.io/region="us-east-2"
kubectl --context k3d-c4 label node k3d-c4-server-0 topology.kubernetes.io/region="us-west-2"
