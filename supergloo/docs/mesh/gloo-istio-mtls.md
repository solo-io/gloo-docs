---
title: "Gloo and Istio mTLS"
weight: 4
---

## Motivation

Serving as the Ingress for an Istio cluster -- without compromising on security -- means supporting
mutual TLS communication between Gloo and the rest of the cluster. Mutual TLS means that the client
proves its identity to the server (in addition to the server proving its identity to the client, which happens in
regular TLS). This process requires quite a bit of setup which SuperGloo abstracts away.

### Prerequisites

1. Istio must already be installed and running in your cluster. See [installing a mesh](../install-istio) for instructions
setting up Istio.
1. The istio book info example must be installed and running in cluster.
See [deploying the book info example](../../tutorials/bookinfo) for instruction on how to install it with auto-injection.

After completing the prerequisite steps run:

```noop
$ kubectl get pods --all-namespaces

NAMESPACE          NAME                                      READY   STATUS      RESTARTS   AGE
default            details-v1-68c7c8666d-wsbqc               2/2     Running     0          9s
default            productpage-v1-54d799c966-jbmpt           2/2     Running     0          9s
default            ratings-v1-8558d4458d-gk976               2/2     Running     0          9s
default            reviews-v1-cb8655c75-pgkzv                2/2     Running     0          9s
default            reviews-v2-7fc9bb6dcf-mdzjg               2/2     Running     0          9s
default            reviews-v3-c995979bc-pp4ms                2/2     Running     0          9s
istio-system       istio-citadel-6f444d9999-v6vcz            1/1     Running     0          28m
istio-system       istio-cleanup-secrets-ncvx8               0/1     Completed   0          28m
istio-system       istio-galley-685bb48846-nxbfs             1/1     Running     0          28m
istio-system       istio-pilot-7959f4df76-gsbf5              2/2     Running     0          28m
istio-system       istio-policy-66ccc8df5f-7b8t9             2/2     Running     0          28m
istio-system       istio-security-post-install-9n5mb         0/1     Completed   0          28m
istio-system       istio-sidecar-injector-5d8dd9448d-wdq9z   1/1     Running     0          28m
istio-system       istio-telemetry-586ccd6d57-kdjnt          2/2     Running     0          28m
supergloo-system   discovery-7bbbf86b66-vw2g5                1/1     Running     0          29m
supergloo-system   supergloo-975bfbfb7-26m2f                 1/1     Running     0          29m
```

If the list includes the following pods then everything should be good to go.

## Installing Gloo with SuperGloo

Once the mandatory prerequisites have been completed, the installation of Gloo using SuperGloo is a single step process.
Assuming that the exact names of the earlier tutorials were used, the command will look as follows.

#### Option 1: CLI

```bash
supergloo install gloo --name gloo --target-meshes supergloo-system.istio
```

#### Option 2: yaml

```yaml
cat << EOF | kubectl apply -f -
apiVersion: supergloo.solo.io/v1
kind: Install
metadata:
  name: gloo
  namespace: supergloo-system
spec:
  ingress:
    gloo:
    glooVersion: 0.13.13
    meshes:
    - name: istio
      namespace: supergloo-system
  installationNamespace: gloo-system
EOF
```

This command should add the following pods

```bash
gloo-system        gateway-9b648f4d-4bnlv                    1/1     Running     0          16s
gloo-system        gateway-proxy-ddf675bc9-sw756             1/1     Running     0          15s
gloo-system        gloo-8576cf6786-t455l                     1/1     Running     0          16s
```

The next step to routing mtls enabled traffic through gloo, is to decide on an upstream to route the traffic to.
In this example we will be using the `details` pod. Using `kubectl` get all available upstreams, and the list should
include the following. This is a list of the istio injected upstreams.

```bash
$ kubectl get upstreams -n supergloo-system

default-details-9080                                    13m
default-details-v1-9080                                 13m
default-kubernetes-443                                  13m
default-productpage-9080                                13m
default-productpage-v1-9080                             13m
default-ratings-9080                                    13m
default-ratings-v1-9080                                 13m
default-reviews-9080                                    13m
default-reviews-v1-9080                                 13m
default-reviews-v2-9080                                 13m
default-reviews-v3-9080                                 13m
```

Once those pods are up and running, you are ready to add an mtls enabled route.

```yaml
cat << EOF | kubectl apply -f -
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: details
  namespace: gloo-system
spec:
  virtualHost:
    domains:
    - '*'
    name: gloo-system.details
    routes:
    - matcher:
        prefix: /
      routeAction:
        single:
          upstream:
            name: default-details-9080
            namespace: supergloo-system
EOF
```

A quick intermediate step before we move on to actually attempting to communicate with these services will be
grabbing the public facing url of the gloo envoy proxy. In order to do this a utility has been added to quickly retrieve
the url for any mesh-ingess. The command is as follows

```bash
PROXY_URL=$(supergloo get mesh-ingress url --target-mesh supergloo-system.gloo)
```

If we attempt to communicate with these pods now via `curl` we will not be able to because `mtls` will fail.

```bash
$ curl -v $PROXY_URL
* Rebuilt URL to: http://192.168.99.101:31823/
*   Trying 192.168.99.101...
* TCP_NODELAY set
* Connected to 192.168.99.101 (192.168.99.101) port 31823 (#0)
> GET / HTTP/1.1
> Host: 192.168.99.101:31823
> User-Agent: curl/7.54.0
> Accept: */*
>
< HTTP/1.1 503 Service Unavailable
< content-length: 95
< content-type: text/plain
< date: Wed, 27 Mar 2019 20:09:33 GMT
< server: envoy
<
* Connection #0 to host 192.168.99.101 left intact
upstream connect error or disconnect/reset before headers. reset reason: connection termination
```

Now that we have verified that we cannot access the route, the next step is to add the certificate to the upstream in
order to tell gloo to enable ssl with the istio certs. supergloo has a command to accomplish just that.

```bash
supergloo set upstream mtls --name  default-details-9080 --target-mesh supergloo-system.istio
```

After this command completes successfully the upstream should contain the following. Notice the certificates in
the sslConfig section of the upstream.

```bash
apiVersion: gloo.solo.io/v1
kind: Upstream
metadata:
  labels:
    app: details
    discovered_by: kubernetesplugin
  name: default-details-9080
  namespace: supergloo-system
spec:
  discoveryMetadata: {}
  upstreamSpec:
    kube:
      selector:
        app: details
      serviceName: details
      serviceNamespace: default
      servicePort: 9080
    sslConfig:
      sslFiles:
        rootCa: /etc/certs/supergloo-system/istio/root-cert.pem
        tlsCert: /etc/certs/supergloo-system/istio/cert-chain.pem
        tlsKey: /etc/certs/supergloo-system/istio/key.pem
```

Now that the upstream has been modified, everything is ready to go. Simply execute the following.

```bash
$ curl -v $PROXY_URL/details/1
*   Trying 192.168.99.101...
* TCP_NODELAY set
* Connected to 192.168.99.101 (192.168.99.101) port 31823 (#0)
> GET /details/1 HTTP/1.1
> Host: 192.168.99.101:31823
> User-Agent: curl/7.54.0
> Accept: */*
>
< HTTP/1.1 200 OK
< content-type: application/json
< server: envoy
< date: Wed, 27 Mar 2019 20:37:33 GMT
< content-length: 178
< x-envoy-upstream-service-time: 4
< x-envoy-decorator-operation: details.default.svc.cluster.local:9080/*
<
* Connection #0 to host 192.168.99.101 left intact
{"id":1,"author":"William Shakespeare","year":1595,"type":"paperback","pages":200,"publisher":"PublisherA","language":"English","ISBN-10":"1234567890","ISBN-13":"123-1234567890"}
```

We were able to connect to an istio injected side car using gloo as an ingress with only 3 commands.
