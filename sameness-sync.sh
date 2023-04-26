set -e

export CLUSTER1_CONTEXT=k3d-c1
export CLUSTER2_CONTEXT=k3d-c2
export CLUSTER3_CONTEXT=k3d-c3
export CLUSTER4_CONTEXT=k3d-c4

export C1_TOKEN=$(kubectl get secrets --context $CLUSTER1_CONTEXT -n consul consul-bootstrap-acl-token -o jsonpath="{.data.token}" | base64 -d)
export C3_TOKEN=$(kubectl get secrets --context $CLUSTER3_CONTEXT -n consul consul-bootstrap-acl-token -o jsonpath="{.data.token}" | base64 -d)
export C4_TOKEN=$(kubectl get secrets --context $CLUSTER4_CONTEXT -n consul consul-bootstrap-acl-token -o jsonpath="{.data.token}" | base64 -d)

envsubst < ./sameness-config-template.json > ./sameness-config.json

./consul-sameness-manager run -config-dir ./sameness-config-entries -members-config ./sameness-config.json
