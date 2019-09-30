---
title: Configuration format history
weight: 100
description: Overview of the external auth configuration formats supported by each GlooE version.
---

#### GlooE versions >=0.19.0

For the latest configuration format see the [main page]({{< ref "gloo_routing/virtual_services/security#configuration-overview" >}}) 
of the authentication section of the docs.

#### GlooE versions <0.19.0

Up to **Gloo Enterprise**, release [**0.19.0**]({{< ref "/changelog#gloo-enterprise" >}}), authentication configuration 
is supported only on **Virtual Hosts**. The configuration has to be specified directly on the Virtual Service CRD:

{{< highlight yaml "hl_lines=18-30" >}}
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: test-auth
  namespace: gloo-system
spec:
  virtualHost:
    domains:
      - 'foo's
    routes:
      - matcher:
          prefix: /authenticated
        routeAction:
          single:
            upstream:
              name: my-upstream
              namespace: gloo-system
    virtualHostPlugins:
      extensions:
        configs:
          extauth:
            basicAuth:
              realm: "test"
              apr:
                users:
                  user:
                    salt: "TYiryv0/"
                    hashedPassword: "8BvzLUO9IfGPGGsPnAgSu1"
{{< /highlight >}}

On a **Route** level, it is only possible to opt out of auth configurations specified on parent Virtual Hosts:

{{< highlight yaml "hl_lines=25-29" >}}
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: test-auth
  namespace: gloo-system
spec:
  virtualHost:
    domains:
      - 'foo'
    routes:
      - matcher:
          prefix: /authenticated
        routeAction:
          single:
            upstream:
              name: my-upstream
              namespace: gloo-system
      - matcher:
          prefix: /skip-auth
        routeAction:
          single:
            upstream:
              name: my-insecure-upstream
              namespace: gloo-system
        routePlugins:
          extensions:
            configs:
              extauth:
                disable: true
    virtualHostPlugins:
      extensions:
        configs:
          extauth:
            basicAuth:
              realm: "test"
              apr:
                users:
                  user:
                    salt: "TYiryv0/"
                    hashedPassword: "8BvzLUO9IfGPGGsPnAgSu1"
{{< /highlight >}}
