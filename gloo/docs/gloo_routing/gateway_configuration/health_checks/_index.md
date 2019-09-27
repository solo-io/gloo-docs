---
title: Health Checks
weight: 4
---

Gloo includes an HTTP health checking plugin that can be enabled in a 
[Gateway]({{% ref "/api/github.com/solo-io/gloo/projects/gateway/api/v1/gateway.proto.sk" %}}) 
(which becomes an [Envoy Listener](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/listeners)). 
This plugin will respond to health check requests directly with either a 200 OK or 503 Service Unavailable 
depending on the current draining state of Envoy.
 
Envoy can be forced into a draining state by sending an `HTTP GET` to the Envoy admin port on `<envoy-ip>:<admin-addr>/healthcheck/fail`.
This port defaults to `19000`. 

To add the health check to a gateway, add the `healthCheck` stanza to the Gateway's `plugins`, like so:

{{< highlight yaml "hl_lines=10-11" >}}
apiVersion: gateway.solo.io/v1
kind: Gateway
metadata:
  name: gateway-proxy-v2
  namespace: gloo-system
spec:
  bindAddress: '::'
  bindPort: 8080
  plugins:
    healthCheck:
      path: /any-path-you-want
{{< /highlight >}}

The HTTP Path of health check requests must be an *exact* match to the provided `healthCheck.path` variable.
