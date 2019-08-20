kubectl --namespace=opa create configmap vs-whitelist --from-file=vs-whitelist.rego

exec kubectl --namespace opa logs -l app=opa -c opa -f