---
title: Gloo and Istio mTLS
weight: 2
---

## Motivation

Serving as the Ingress for an Istio cluster -- without compromising on security -- means supporting 
mutual TLS communication between Gloo and the rest of the cluster. Mutual TLS means that the client 
proves its identity to the server (in addition to the server proving its identity to the client, which happens in regular TLS).

## Prerequisites
We you need Istio install with mTLS enabled. This guide was tested with istio 1.0.6.
For a quick install of Istio on minikube, run the following commands:
```bash
kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml
kubectl apply -f install/kubernetes/istio-demo-auth.yaml
kubectl get pods -w -n istio-system
```

Use `kubectl get pods -n istio-system` to check the status on the istio pods, and wait until all the 
pods are **Running** or **Completed**.

Install bookinfo sample app:
```bash
kubectl label namespace default istio-injection=enabled
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
```

This guide also assumes that you have Gloo installed. Gloo is installed to the gloo-system namespace
and should *not* be injected with the istio sidecar.
To quickly install Gloo, download *glooctl* and run `glooctl install gateway`. See the 
[quick start](../../installation/kubernetes/quick_start/) guide for more information.

## Configure Gloo
For Gloo to successfully send requests to an Istio upstream with mTLS enabled, we need to add
the Istio mTLS secret to the gateway-proxy pod. The secret allows Gloo to authenticate with the 
upstream service.

Edit the pod, with the command `kubectl edit -n gloo-system deploy/gateway-proxy`, 
and add istio certs volume and volume mounts. Here's an example of an edited deployment:
{{< highlight yaml "hl_lines=43-45 50-54" >}}
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: gloo
    gloo: gateway-proxy
  name: gateway-proxy
  namespace: gloo-system
spec:
  replicas: 1
  selector:
    matchLabels:
      gloo: gateway-proxy
  template:
    metadata:
      labels:
        gloo: gateway-proxy
    spec:
      containers:
      - args: ["--disable-hot-restart"]
        env:
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        image: soloio/gloo-envoy-wrapper:0.8.6
        imagePullPolicy: Always
        name: gateway-proxy
        ports:
        - containerPort: 8080
          name: http
          protocol: TCP
        - containerPort: 8443
          name: https
          protocol: TCP
        volumeMounts:
        - mountPath: /etc/envoy
          name: envoy-config
        - mountPath: /etc/certs/
          name: istio-certs
          readOnly: true
      volumes:
      - configMap:
          name: gateway-envoy-config
        name: envoy-config
      - name: istio-certs
        secret:
          defaultMode: 420
          optional: true
          secretName: istio.default
{{< /highlight >}}

The Gloo gateway will now have access to Istio client secrets. The last configuration step is to 
configure the relevant upstreams with mTLS. This gives us the flexibility to route both to upstreams
with and without mTLS enabled - a common occurance in a brown field envrionment or during a migration to Istio.

Let's edit the product page upstream and tell Gloo to use the secrets configured in the 
previous step.

Edit the upstream with the command `kubectl edit upstream default-productpage-9080 --namespace gloo-system`. The updated upstream should look like this:
{{< highlight yaml "hl_lines=20-24" >}}
apiVersion: gloo.solo.io/v1
kind: Upstream
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"labels":{"app":"productpage"},"name":"productpage","namespace":"default"},"spec":{"ports":[{"name":"http","port":9080}],"selector":{"app":"productpage"}}}
  creationTimestamp: 2019-02-27T03:00:44Z
  generation: 1
  labels:
    app: productpage
    discovered_by: kubernetesplugin
  name: default-productpage-9080
  namespace: gloo-system
  resourceVersion: "3409"
  selfLink: /apis/gloo.solo.io/v1/namespaces/gloo-system/upstreams/default-productpage-9080
  uid: dfd33b6c-3a3b-11e9-98c6-02425fecee06
spec:
  discoveryMetadata: {}
  upstreamSpec:
    sslConfig:
      sslFiles:
        tlsCert: /etc/certs/cert-chain.pem
        tlsKey: /etc/certs/key.pem
        rootCa: /etc/certs/root-cert.pem
    kube:
      selector:
        app: productpage
      serviceName: productpage
      serviceNamespace: default
      servicePort: 9080
status:
  reported_by: gloo
  state: 1
{{< /highlight >}}

## Add Routes

Now we can successfully route to the upstream via Gloo:

```bash
glooctl add route --name prodpage --namespace gloo-system --path-prefix / --dest-name default-productpage-9080 --dest-namespace gloo-system
```

Access the ingress url:
```
INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o 'jsonpath={.items[0].status.hostIP}')
HTTP_GW=http://$INGRESS_HOST:$(kubectl -ngloo-system get service gateway-proxy -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}') 
## Open the ingress url in the browser:
$([ "$(uname -s)" = "Linux" ] && echo xdg-open || echo open) $HTTP_GW
```

That's it! Get Glooing!