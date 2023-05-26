set +e

export CLIENT_NS=ns1

kubectl exec -it --context k3d-c1 -n $CLIENT_NS deploy/static-client -c static-client -- curl localhost:8080/
echo ""
kubectl exec -it --context k3d-c2 -n $CLIENT_NS deploy/static-client -c static-client -- curl localhost:8080/
echo ""
kubectl exec -it --context k3d-c3 -n $CLIENT_NS deploy/static-client -c static-client -- curl localhost:8080/
echo ""
kubectl exec -it --context k3d-c4 -n $CLIENT_NS deploy/static-client -c static-client -- curl localhost:8080/
