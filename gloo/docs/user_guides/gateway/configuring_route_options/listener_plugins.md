---
title: Listener Plugins
menuTitle: Listener Plugins
weight: 39
description: Advanced listener Plugins for modifying behavior of virtual services.
---

Gloo allows you to configure properties of your gateways with several plugins.
This guide shows you how to apply these advanced listener configurations to refine your gateways' behavior.

## Overview

For demonstration purposes, let's edit the default gateways that are installed with `glooctl install gateway`.
You can list and edit gateways with `kubectl`.

```bash
kubectl get gateway --all-namespaces
NAMESPACE     NAME          AGE
gloo-system   gateway       2d
gloo-system   gateway-ssl   2d
```

`kubectl edit gateway -n gloo-system gateway`

### Plugin summary

The listener plugin portion of the gateway crd is shown below.

{{< highlight yaml "hl_lines=7-11" >}}
apiVersion: gateway.solo.io/v1
kind: Gateway
metadata: # collapsed for brevity
spec:
  bindAddress: '::'
  bindPort: 8080
  plugins:
    grpcWeb:
      disable: true
    httpConnectionManagerSettings:
      via: reference-string
  useProxyProto: false
status: # collapsed for brevity
{{< /highlight >}}


### Verify your configuration

To verify that your configuration was accepted, inspect the proxy CRDs. They should have the values you specified. 

```bash
kubectl get proxy  --all-namespaces -o yaml
```

{{< highlight yaml "hl_lines=11-15" >}}
apiVersion: v1
items:
- apiVersion: gloo.solo.io/v1
  kind: Proxy
  metadata: # collapsed for brevity
  spec:
    listeners:
    - bindAddress: '::'
      bindPort: 8080
      httpListener:
        listenerPlugins:
          grpcWeb:
            disable: true
          httpConnectionManagerSettings:
            via: reference-string
        virtualHosts:
        - domains:
          - '*'
          name: gloo-system.merged-*
        - domains:
          - solo.io
          name: gloo-system.myvs3
      name: listener-::-8080
      useProxyProto: false
    - bindAddress: '::'
      bindPort: 8443
      httpListener: {}
      name: listener-::-8443
      useProxyProto: false
  status: # collapsed for brevity
kind: List
metadata: # collapsed for brevity
{{< /highlight >}}


## HTTP Connection Manager Plugin

The HTTP Connection Manager lets you refine the behavior of Envoy for each listener that you manage with Gloo.

### Tracing

One of the fields in the HTTP Connection Manager Plugin is `tracing`. This specifies the listener-specific tracing configuration.

For notes on configuring and using tracing with Gloo, please see the [tracing setup docs.](../../../setup_options/observability/#configuration)

The tracing configuration fields of the Gateway CRD are highlighted below.

{{< highlight yaml "hl_lines=7-13" >}}
apiVersion: gateway.solo.io/v1
kind: Gateway
metadata: # collapsed for brevity
spec:
  bindAddress: '::'
  bindPort: 8080
  plugins:
    httpConnectionManagerSettings:
      tracing:
        requestHeadersForTags:
          - path
          - origin
        verbose: true
  useProxyProto: false
status: # collapsed for brevity
{{< /highlight >}}

### Advanced listener configuration

Gloo exposes Envoy's powerful configuration capabilities with the HTTP Connection Manager. The details of these fields can be found [here](https://www.envoyproxy.io/docs/envoy/v1.9.0/configuration/http_conn_man/http_conn_man) and [here](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/core/protocol.proto#envoy-api-msg-core-http1protocoloptions)

Below, see a reference configuration specification to demonstrate the structure of the expected yaml.

{{< highlight yaml "hl_lines=7-23" >}}
apiVersion: gateway.solo.io/v1
kind: Gateway
metadata: # collapsed for brevity
spec:
  bindAddress: '::'
  bindPort: 8080
  plugins:
    httpConnectionManagerSettings:
      skipXffAppend: false
      via: reference-string
      xffNumTrustedHops: 1234
      useRemoteAddress: false
      generateRequestId: false
      proxy100Continue: false
      streamIdleTimeout: 1m2s
      idleTimeout: 1m2s
      maxRequestHeadersKb: 1234
      requestTimeout: 1m2s
      drainTimeout: 1m2s
      delayedCloseTimeout: 1m2s
      serverName: reference-string
      acceptHttp10: false
      defaultHostForHttp10: reference-string
  useProxyProto: false
status: # collapsed for brevity
{{< /highlight >}}




## gRPC Web Plugin

In order to serve gRPC Web clients, the server must first transcode the message into a format that the web client can understand [details](https://github.com/grpc/grpc/blob/master/doc/PROTOCOL-WEB.md#protocol-differences-vs-grpc-over-http2). Gloo configures Envoy to do this by default. If you would like to disable this behavior, you can do so with:

{{< highlight yaml "hl_lines=7-9" >}}
apiVersion: gateway.solo.io/v1
kind: Gateway
metadata: # collapsed for brevity
spec:
  bindAddress: '::'
  bindPort: 8080
  plugins:
    grpcWeb:
      disable: true
  useProxyProto: false
status: # collapsed for brevity
{{< /highlight >}}


