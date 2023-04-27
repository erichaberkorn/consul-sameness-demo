#!/bin/bash

set -e

eval $(cat .env)

export C1_TOKEN=$(kubectl get secrets --context $CLUSTER1_CONTEXT -n consul consul-bootstrap-acl-token -o jsonpath="{.data.token}" | base64 -d)
export C3_TOKEN=$(kubectl get secrets --context $CLUSTER3_CONTEXT -n consul consul-bootstrap-acl-token -o jsonpath="{.data.token}" | base64 -d)
export C4_TOKEN=$(kubectl get secrets --context $CLUSTER4_CONTEXT -n consul consul-bootstrap-acl-token -o jsonpath="{.data.token}" | base64 -d)
export CLUSTER_CONTEXTS=("$CLUSTER1_CONTEXT" "$CLUSTER2_CONTEXT" "$CLUSTER3_CONTEXT" "$CLUSTER4_CONTEXT")

tmp_folder=$(mktemp -d)
tmp_cfg=$(mktemp)

for cluster_context in "${CLUSTER_CONTEXTS[@]}"; do
  envsubst < "./crds/static-server-service-defaults.yaml" | kubectl --context $cluster_context apply -f -
  envsubst < "./crds/sameness.yaml" | kubectl --context $cluster_context apply -f -
  if [ "$cluster_context" != "$CLUSTER2_CONTEXT" ]; then
    envsubst < "./crds/mesh.yaml" | kubectl --context $cluster_context apply -f -
  fi
done

for file in $(find ./crds -type f ! -name "static-server-service-defaults.yaml" ! -name "sameness.yaml" ! -name "mesh.yaml"); do
  for cluster_context in "${CLUSTER_CONTEXTS[@]}"; do
    export PARTITION=default
    if [ "$cluster_context" == "$CLUSTER2_CONTEXT" ]; then
      export PARTITION=ap1
    fi
    envsubst < "$file" | kubectl --context $cluster_context apply -f -
  done
done

peer_clusters() {
  export ACCEPTOR="$1"
  local ACCEPTOR_CTX="$2"
  export DIALER="$3"
  local DIALER_CTX="$4"

  envsubst < "./acceptor-template.yaml" | kubectl --context $ACCEPTOR_CTX apply -f -

  export DIALER_SECRET=""
  counter=0
  while [ -z "$DIALER_SECRET" ] && [ $counter -lt 3 ]; do
    DIALER_SECRET=$(kubectl get secret --context "$DIALER_CTX" "$ACCEPTOR-peering-token" -o yaml || true)
    [ -z "$DIALER_SECRET" ] && sleep 1
    ((counter++))
  done

  if [ -z "$DIALER_SECRET" ]; then
    export SECRET=""
    while [ -z "$SECRET" ]; do
      SECRET=$(kubectl get secret --context "$ACCEPTOR_CTX" "$DIALER-peering-token" -o yaml || true)
      [ -z "$SECRET" ] && sleep 1
    done

    echo "$SECRET" | yq '.metadata.name = env(ACCEPTOR) + "-peering-token"' | kubectl --context $DIALER_CTX apply -f -

    envsubst < "./dialer-template.yaml" | kubectl --context $DIALER_CTX apply -f -
  fi
}

peer_clusters "cluster-01-a" "$CLUSTER1_CONTEXT" "cluster-02-a" "$CLUSTER3_CONTEXT"
peer_clusters "cluster-01-a" "$CLUSTER1_CONTEXT" "cluster-03-a" "$CLUSTER4_CONTEXT"
peer_clusters "cluster-01-b" "$CLUSTER2_CONTEXT" "cluster-02-a" "$CLUSTER3_CONTEXT"
peer_clusters "cluster-01-b" "$CLUSTER2_CONTEXT" "cluster-03-a" "$CLUSTER4_CONTEXT"
peer_clusters "cluster-02-a" "$CLUSTER3_CONTEXT" "cluster-03-a" "$CLUSTER4_CONTEXT"
