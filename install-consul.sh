#!/bin/bash

set -e

eval $(cat .env)
eval $(cat k8sImages.env)

export CHART_PATH=$1

CLUSTER_CONTEXTS=("$CLUSTER1_CONTEXT" "$CLUSTER2_CONTEXT" "$CLUSTER3_CONTEXT" "$CLUSTER4_CONTEXT")

create_namespace() {
  local cluster_context="$1"
  local namespace="$2"
  kubectl --context $cluster_context create namespace $namespace
}

create_secret() {
  local cluster_context="$1"
  local namespace="$2"
  local secret_name="$3"
  local file="$4"
  kubectl --context $cluster_context -n $namespace create secret generic $secret_name --from-file=$file
}

for cluster_context in "${CLUSTER_CONTEXTS[@]}"; do
  create_namespace "$cluster_context" "$CONSUL_NS"
  create_namespace "$cluster_context" "$SERVER_NS"
  create_namespace "$cluster_context" "$CLIENT_NS"
  create_secret $cluster_context "consul" "license" "license.txt"
done

export HELM_RELEASE_NAME=cluster-01
helm install ${HELM_RELEASE_NAME} $CHART_PATH --create-namespace --namespace "$CONSUL_NS" --version "1.1.1" --values values-ent.yaml --set global.datacenter=dc1 --set global.image="$CONSUL_IMAGE" --set global.imageK8S="$CONSUL_K8S_IMAGE" --kube-context $CLUSTER1_CONTEXT

export C1_CA_CERT=""
while [ -z "$C1_CA_CERT" ]; do
  C1_CA_CERT=$(kubectl get secret --context $CLUSTER1_CONTEXT --namespace "$CONSUL_NS" consul-ca-cert -o yaml)
  [ -z "$C1_CA_CERT" ] && sleep 1
done

export C1_CA_KEY=""
while [ -z "$C1_CA_KEY" ]; do
  C1_CA_KEY=$(kubectl get secret --context $CLUSTER1_CONTEXT --namespace "$CONSUL_NS" consul-ca-key -o yaml)
  [ -z "$C1_CA_KEY" ] && sleep 1
done

export HOST=""
while [ -z "$HOST" ]; do
  HOST=$(kubectl get svc --context $CLUSTER1_CONTEXT -n "$CONSUL_NS" consul-expose-servers -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>&1)
  [ -z "$HOST" ] && sleep 1
done

export AUTH_METHOD_URL=""
while [ -z "$AUTH_METHOD_URL" ]; do
  AUTH_METHOD_URL=$(kubectl get endpoints kubernetes --context $CLUSTER2_CONTEXT -o jsonpath='https://{.subsets[0].addresses[0].ip}:{.subsets[0].ports[0].port}')
  [ -z "$AUTH_METHOD_URL" ] && sleep 1
done

export BOOTSTRAP=""
while [ -z "$BOOTSTRAP" ]; do
  BOOTSTRAP=$(kubectl get secret consul-partitions-acl-token --context $CLUSTER1_CONTEXT -n "$CONSUL_NS" -o yaml)
  [ -z "$BOOTSTRAP" ] && sleep 1
done

echo "$BOOTSTRAP" | kubectl apply -n "$CONSUL_NS" --context $CLUSTER2_CONTEXT --filename -

echo "$C1_CA_CERT" | kubectl --context $CLUSTER2_CONTEXT apply --namespace "$CONSUL_NS" -f -
echo "$C1_CA_KEY" | kubectl --context $CLUSTER2_CONTEXT apply --namespace "$CONSUL_NS" -f -

export HELM_RELEASE_NAME=cluster-01-ap1
helm install ${HELM_RELEASE_NAME} $CHART_PATH --create-namespace --namespace "$CONSUL_NS" --version "1.1.1" --values values-ap1.yaml --set global.datacenter=dc1 --set global.image="$CONSUL_IMAGE" --set global.imageK8S="$CONSUL_K8S_IMAGE" --set "externalServers.hosts[0]=$HOST" --set "externalServers.k8sAuthMethodHost=$AUTH_METHOD_URL" --kube-context $CLUSTER2_CONTEXT

export HELM_RELEASE_NAME=cluster-02
helm install ${HELM_RELEASE_NAME} $CHART_PATH --create-namespace --namespace "$CONSUL_NS" --version "1.1.1" --values values-ent.yaml --set global.datacenter=dc2 --set global.image="$CONSUL_IMAGE" --set global.imageK8S="$CONSUL_K8S_IMAGE" --kube-context $CLUSTER3_CONTEXT

export HELM_RELEASE_NAME=cluster-03
helm install ${HELM_RELEASE_NAME} $CHART_PATH --create-namespace --namespace "$CONSUL_NS" --version "1.1.1" --values values-ent.yaml --set global.datacenter=dc3 --set global.image="$CONSUL_IMAGE" --set global.imageK8S="$CONSUL_K8S_IMAGE" --kube-context $CLUSTER4_CONTEXT
