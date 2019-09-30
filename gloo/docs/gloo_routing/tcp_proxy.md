---
title: TCP Proxy
weight: 40
description: In this tutorial, we'll take a look at using gloo as a TCP proxy.
---

In this tutorial, we'll take a look at using gloo as a TCP proxy. Envoy by default is an L4 proxy and is therefore
more than up to the task. Gloo's TCP routing feature are slightly different than the rest of Gloo's routing as a result
of the relative simplicity of TCP level routing. Current features include standard routing, ssl, and sni domain matching.

### Resources 

For reference on  the 

- [Gateway]({{% ref "/api/github.com/solo-io/gloo/projects/gateway/api/v2/gateway.proto.sk" %}})
- [Proxy]({{% ref "/api/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk" %}})

### What you'll need

You'll need to have Gloo installed on Kubernetes and have access to that Kubernetes cluster. Please refer to the
[Gloo installation]({{< ref "/installation" >}}) for guidance on installing Gloo into Kubernetes.

You'll also need access from the Kubernetes cluster to an external API. You will also need an accessible TCP service running 
in cluster, this may be anything, for the purposes of this tutorial we will use a basic tcp-echo pod.

Firstly apply the following yaml into the namespace of your choice. For the purposes of this tutorial we will be using `gloo-system`

```bash
kubectl apply -n gloo-system -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  labels:
    gloo: tcp-echo
  name: tcp-echo
spec:
  containers:
  - image: soloio/tcp-echo:latest
    imagePullPolicy: IfNotPresent
    name: tcp-echo
  restartPolicy: Always
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: gloo
  name: tcp-echo
spec:
  ports:
  - name: http
    port: 1025
    protocol: TCP
    targetPort: 1025
  selector:
    gloo: tcp-echo
EOF
```

Once the `tcp-echo` pod is up and running we are ready to create our gateway resource and begin routing to it.

As of vesion v2 of the [gateway]({{% ref "/api/github.com/solo-io/gloo/projects/gateway/api/v2/gateway.proto.sk" %}}) 
resource, it now supports 2 different types, those being HTTP, and TCP. 
The [proxy]({{% ref "/api/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk" %}}) resource has been extended as well with
the TCP listener type. This is not a breaking change and therefore does not require an API upgrade. 

The gateway will contain the following: 
```bash
kubectl apply -n gloo-system -f - <<EOF
apiVersion: gateway.solo.io.v2/v2
kind: Gateway
metadata:
  name: tcp
  namespace: gloo-system
spec:
  bindAddress: '::'
  bindPort: 8000
  tcpGateway:
    destinations:
    - name: one
      destination:
        single:
          upstream:
            name: gloo-system-tcp-echo-1025
            namespace: gloo-system
  useProxyProto: false
EOF
```

To check that the gateway has been created properly run:
```bash
$ kubectl get gateways.gateway.solo.io -A

NAMESPACE     NAME          AGE
gloo-system   gateway       26h
gloo-system   gateway-ssl   26h
gloo-system   tcp           5s
```


The above gateway will be read in by gloo, which will combine it with the other gateways into a Proxy resource.
To make sure that the configuration has been translated properly run:

{{< highlight yaml "hl_lines=22-29" >}}
$ kubectl get proxies.gloo.solo.io -n gloo-system -oyaml

apiVersion: v1
items:
- apiVersion: gloo.solo.io/v1
  kind: Proxy
  metadata:
    creationTimestamp: "2019-07-05T16:01:14Z"
    generation: 48
    labels:
      created_by: gateway
    name: gateway-proxy
    namespace: gloo-system
    resourceVersion: "150947"
    selfLink: /apis/gloo.solo.io/v1/namespaces/gloo-system/proxies/gateway-proxy
    uid: 1d7b84d2-9f3e-11e9-8766-3e49e0c5bb1c
  spec:
    listeners:
    - bindAddress: '::'
      bindPort: 8000
      name: listener-::-8000
      tcpListener:
        tcpHosts:
        - destination:
            single:
              upstream:
                name: gloo-system-tcp-echo-1025
                namespace: gloo-system
          name: one
      useProxyProto: false
  status:
    reported_by: gloo
    state: 1
kind: List
metadata:
  resourceVersion: ""
  selfLink: ""
{{< /highlight >}}


If the translation worked than the listeners array in the resource spec will contain an entry for the tcp service we will be routing to.
Once the state on the resource is recorded as `1` the service is ready to be routed to.

The next step is adding a port to the gateway-proxy service so we can route to the envoy listener which is handling our TCP traffic.

The service should look like the following:

{{< highlight yaml "hl_lines=23-27" >}}
apiVersion: v1
kind: Service
metadata:
  labels:
    app: gloo
    gloo: gateway-proxy
  name: gateway-proxy
  namespace: gloo-systemservices/gateway-proxy
  uid: 1b624541-9f3e-11e9-8766-3e49e0c5bb1c
spec:
  externalTrafficPolicy: Cluster
  ports:
  - name: http
    nodePort: 32302
    port: 80
    protocol: TCP
    targetPort: 8080
  - name: https
    nodePort: 30440
    port: 443
    protocol: TCP
    targetPort: 8443
  - name: tcp
    nodePort: 30197
    port: 8000
    protocol: TCP
    targetPort: 8000
  selector:
    gloo: gateway-proxy
  sessionAffinity: None
  type: LoadBalancer
status:
  loadBalancer: {}
{{< /highlight >}}

The important part here is the entry on port `8000` for our tcp service. Once the service has been saved to kubernetes, get the NodePort from the
service port entry and save it for later.

The next and final step is routing to the service.
This step assumes you are running on a local minikube instance.
```bash
curl -v telnet://$(minikube ip):30197

* Rebuilt URL to: telnet://192.168.64.13:30197/
*   Trying 192.168.64.13...
* TCP_NODELAY set
* Connected to 192.168.64.13 (192.168.64.13) port 30197 (#0)

```

{{% notice note %}}
note: The node port was inserted in the above command following the ip
{{% /notice %}}


Now the terminal is waiting for input, all input entered will be echo'd back. And an inspection of the logs from the pod will reveal that the data
is in fact being proxied through.
