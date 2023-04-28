set -e

CTX="k3d-c$1"
eval $(cat namespaces.sh)

kubectl scale --context $CTX -n $SERVER_NS deploy/static-server --replicas=$2
