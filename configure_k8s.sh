set -e

mkdir -p manifests/c1
mkdir -p manifests/c2
mkdir -p manifests/c3
mkdir -p manifests/c4

export peer=cluster-01-a
export ns=default
cat static-server-template.yaml | yq  '((select(.kind == "Deployment") | .spec.template.spec.containers[0].args[0]) |= "-text=" + strenv(peer)) | (.metadata.namespace = strenv(ns))' > manifests/c1/static-server.yaml
cat static-client-template.yaml | yq  '(.metadata.namespace = strenv(ns))' > manifests/c1/static-client.yaml

export peer=cluster-01-b
export ns=default
cat static-server-template.yaml | yq  '((select(.kind == "Deployment") | .spec.template.spec.containers[0].args[0]) |= "-text=" + strenv(peer)) | (.metadata.namespace = strenv(ns))' > manifests/c2/static-server.yaml
cat static-client-template.yaml | yq  '(.metadata.namespace = strenv(ns))' > manifests/c2/static-client.yaml

export peer=cluster-02
export ns=default
cat static-server-template.yaml | yq  '((select(.kind == "Deployment") | .spec.template.spec.containers[0].args[0]) |= "-text=" + strenv(peer)) | (.metadata.namespace = strenv(ns))' > manifests/c3/static-server.yaml
cat static-client-template.yaml | yq  '(.metadata.namespace = strenv(ns))' > manifests/c3/static-client.yaml

export peer=cluster-03
export ns=default
cat static-server-template.yaml | yq  '((select(.kind == "Deployment") | .spec.template.spec.containers[0].args[0]) |= "-text=" + strenv(peer)) | (.metadata.namespace = strenv(ns))' > manifests/c4/static-server.yaml
cat static-client-template.yaml | yq  '(.metadata.namespace = strenv(ns))' > manifests/c4/static-client.yaml

export CLUSTER1_CONTEXT=k3d-c1
export CLUSTER2_CONTEXT=k3d-c2
export CLUSTER3_CONTEXT=k3d-c3
export CLUSTER4_CONTEXT=k3d-c4

kubectl --context $CLUSTER1_CONTEXT apply -f manifests/c1
kubectl --context $CLUSTER2_CONTEXT apply -f manifests/c2
kubectl --context $CLUSTER3_CONTEXT apply -f manifests/c3
kubectl --context $CLUSTER4_CONTEXT apply -f manifests/c4
