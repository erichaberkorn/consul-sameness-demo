set -e

export CLUSTER1_CONTEXT=k3d-c1
export CLUSTER2_CONTEXT=k3d-c2
export CLUSTER3_CONTEXT=k3d-c3
export CLUSTER4_CONTEXT=k3d-c4

kubectl --context $CLUSTER1_CONTEXT create namespace consul
kubectl --context $CLUSTER2_CONTEXT create namespace consul
kubectl --context $CLUSTER3_CONTEXT create namespace consul
kubectl --context $CLUSTER4_CONTEXT create namespace consul

kubectl --context $CLUSTER1_CONTEXT -n consul create secret generic license --from-file=license.txt
kubectl --context $CLUSTER2_CONTEXT -n consul create secret generic license --from-file=license.txt
kubectl --context $CLUSTER3_CONTEXT -n consul create secret generic license --from-file=license.txt
kubectl --context $CLUSTER4_CONTEXT -n consul create secret generic license --from-file=license.txt

export HELM_RELEASE_NAME=cluster-01
helm install ${HELM_RELEASE_NAME} hashicorp/consul --create-namespace --namespace consul --version "1.1.0" --values values-ent.yaml --set global.datacenter=dc1 --kube-context $CLUSTER1_CONTEXT

while ! kubectl get secret --context $CLUSTER1_CONTEXT --namespace consul consul-ca-cert -o yaml >/dev/null 2>&1; do
  sleep 1
done

while ! kubectl get secret --context $CLUSTER1_CONTEXT --namespace consul consul-ca-key -o yaml >/dev/null 2>&1; do
  sleep 1
done

export HOST=""
while [ -z "$HOST" ]; do
  HOST=$(kubectl get svc --context $CLUSTER1_CONTEXT -n consul consul-expose-servers -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>&1)
  [ -z "$HOST" ] && sleep 1
done

kubectl get secret --context $CLUSTER1_CONTEXT --namespace consul consul-ca-cert -o yaml | kubectl --context $CLUSTER2_CONTEXT apply --namespace consul -f -
kubectl get secret --context $CLUSTER1_CONTEXT --namespace consul consul-ca-key -o yaml | kubectl --context $CLUSTER2_CONTEXT apply --namespace consul -f -

export HELM_RELEASE_NAME=cluster-01-ap1
helm install ${HELM_RELEASE_NAME} hashicorp/consul --create-namespace --namespace consul --version "1.1.0" --values values-ap1.yaml --set global.datacenter=dc1 --set "externalServers.hosts[0]=$HOST" --kube-context $CLUSTER2_CONTEXT

export HELM_RELEASE_NAME=cluster-02
helm install ${HELM_RELEASE_NAME} hashicorp/consul --create-namespace --namespace consul --version "1.1.0" --values values-ent.yaml --set global.datacenter=dc2 --kube-context $CLUSTER3_CONTEXT

export HELM_RELEASE_NAME=cluster-03
helm install ${HELM_RELEASE_NAME} hashicorp/consul --create-namespace --namespace consul --version "1.1.0" --values values-ent.yaml --set global.datacenter=dc2 --kube-context $CLUSTER4_CONTEXT
