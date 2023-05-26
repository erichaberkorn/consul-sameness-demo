export CLUSTER1_CONTEXT=k3d-c1
export CLUSTER3_CONTEXT=k3d-c3
export CLUSTER4_CONTEXT=k3d-c4

trap 'kill $(jobs -p)' EXIT
kubectl --context $CLUSTER1_CONTEXT -n consul port-forward consul-server-0 8501:8501 &
kubectl --context $CLUSTER3_CONTEXT -n consul port-forward consul-server-0 8502:8501 &
kubectl --context $CLUSTER4_CONTEXT -n consul port-forward consul-server-0 8503:8501
