---
title: Shadowing
weight: 54
description: Enables traffic shadowing for the route.
---


Enables traffic shadowing for the route.

* `upstream` : Indicates the upstream to which to send the shadowed traffic.
* `percentage` : Percent of traffic to shadow (must be an integer between 0 and 100).

Traffic shadowing is useful when you want to preview the behavior of a service in response to real production traffic without having to deploy your service
in the critical path of production traffic.
In the example below, all traffic going to `petstore` is also forwarded to `petstore-v2`.
{{< highlight yaml "hl_lines=19-23" >}}
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: 'default'
  namespace: 'gloo-system'
spec:
  virtualHost:
    domains:
    - '*'
    routes:
    - matcher:
        prefix: '/petstore'
      routeAction:
        single:
          upstream:
            name: 'petstore'
            namespace: 'gloo-system'
      routePlugins:
        shadowing:
          upstream:
            name: 'petstore-v2'
            namespace: 'gloo-system'
          percentage: 100
{{< /highlight >}}
