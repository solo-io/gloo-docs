kubectl delete validatingwebhookconfiguration  opa-validating-webhook
kubectl delete namespace opa
kubectl delete clusterrolebinding opa-viewer opa-gloo-viewer

rm ca.crt ca.key ca.srl server.conf server.crt server.csr server.key