set -e

export CLUSTER1_CONTEXT=k3d-c1
export CLUSTER2_CONTEXT=k3d-c2
export CLUSTER3_CONTEXT=k3d-c3
export CLUSTER4_CONTEXT=k3d-c4

eval $(cat namespaces.sh)

apply_templates() {
  local cluster_context="$1"
  export PEER="$2"
  export PARTITION="$3"

  envsubst < static-server-template.yaml | kubectl apply --context "$cluster_context" -f -
  envsubst < static-client-template.yaml | kubectl apply --context "$cluster_context" -f -
}

apply_templates "$CLUSTER1_CONTEXT" "cluster-01-a" "default"
apply_templates "$CLUSTER2_CONTEXT" "cluster-01-b" "ap1"
apply_templates "$CLUSTER3_CONTEXT" "cluster-02" "default"
apply_templates "$CLUSTER4_CONTEXT" "cluster-03" "default"
