set -e

export CTX=k3d-c1
eval $(cat .env)

kubectl exec -it --context $CTX -n $CLIENT_NS deploy/static-client -c static-client -- curl localhost:8080
