set -e

eval $(cat namespaces.sh)

export CLUSTER1_CONTEXT=k3d-c1
export CLUSTER2_CONTEXT=k3d-c2
export CLUSTER3_CONTEXT=k3d-c3
export CLUSTER4_CONTEXT=k3d-c4

export C1_TOKEN=$(kubectl get secrets --context $CLUSTER1_CONTEXT -n consul consul-bootstrap-acl-token -o jsonpath="{.data.token}" | base64 -d)
export C3_TOKEN=$(kubectl get secrets --context $CLUSTER3_CONTEXT -n consul consul-bootstrap-acl-token -o jsonpath="{.data.token}" | base64 -d)
export C4_TOKEN=$(kubectl get secrets --context $CLUSTER4_CONTEXT -n consul consul-bootstrap-acl-token -o jsonpath="{.data.token}" | base64 -d)

tmp_folder=$(mktemp -d)
tmp_cfg=$(mktemp)

for file in $(find ./sameness-config-entries -type f); do
  envsubst < "$file" > "$tmp_folder/$(basename $file)"
done

envsubst < ./sameness-config-template.json > "$tmp_cfg"

./consul-sameness-manager run -config-dir $tmp_folder -members-config $tmp_cfg
