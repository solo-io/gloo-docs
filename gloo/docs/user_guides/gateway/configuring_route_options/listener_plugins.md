---
title: Listener Plugins
menuTitle: Listener Plugins
weight: 39
description: Advanced listener Plugins for modifying behavior of virtual services.
---

Gloo allows you to configure properties of the virtual service (listener) with several plugins.

## HTTP Connection Manager

The HTTP Connection Manager lets you refine the behavior of Envoy for each listener that you manage with Gloo.

For demonstration purposes, let's edit an existing gateway to include some features of the listener plugin.

```bash
kubectl get gateway --all-namespaces
NAMESPACE     NAME          AGE
gloo-system   gateway       2d
gloo-system   gateway-ssl   2d
```

`kubectl edit gateway -n gloo-system gateway`


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
      via: ok
  useProxyProto: false
status: # collapsed for brevity
{{< /highlight >}}

### Tracing



## Web gRPC

