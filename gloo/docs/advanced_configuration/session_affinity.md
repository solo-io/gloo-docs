---
title: Session Affinity
weight: 48
description: Configure Gloo session affinity (sticky sessions)
---

# Session Affinity

For certain applications deployed across multiple replicas, it may be desireable
to route all traffic from a single client session to the same instance of the
application. This can help reduce latency through better use of caches. This
load balancer behavior is referred to as Session Affinity or Sticky Sessions.
Gloo exposes Envoy's full session affinity capabilities, as described below.


## Configuration overview

There are two steps to configuring session affinity:

1. Set a hashing load balancer on the upstream specification.
  - This can be either Envoy's Ring Hash or Maglev load balancer.
1. Define the hash key parameters on the desired routes.
  - This can include any combination of headers, cookies, and source IP address.



### Upstream Plugin Configuration

- Whether an upstream was discovered by Gloo or created manually, just add the `loadBalancerConfig` spec to your upstream.
- Either a `ringHash` or `maglev` load balancer must be specified. Some examples are shown below.

#### Ring Hash Upstream Example

- Full specification

{{< highlight yaml "hl_lines=17-21" >}}
apiVersion: gloo.solo.io/v1
kind: Upstream
metadata:
  annotations:
  labels:
    discovered_by: kubernetesplugin
  name: default-session-affinity-app-80
  namespace: gloo-system
spec:
  upstreamSpec:
    kube:
      selector:
        name: session-affinity-app
      serviceName: session-affinity-app
      serviceNamespace: default
      servicePort: 80
    loadBalancerConfig:
      ringHash:
        ringHashConfig:
          maximumRingSize: "200"
          minimumRingSize: "10"
{{< /highlight >}}

- Optional fields omitted

{{< highlight yaml "hl_lines=17-18" >}}
apiVersion: gloo.solo.io/v1
kind: Upstream
metadata:
  annotations:
  labels:
    discovered_by: kubernetesplugin
  name: default-session-affinity-app-80
  namespace: gloo-system
spec:
  upstreamSpec:
    kube:
      selector:
        name: session-affinity-app
      serviceName: session-affinity-app
      serviceNamespace: default
      servicePort: 80
    loadBalancerConfig:
      ringHash: {}
{{< /highlight >}}

#### Maglev Upstream Example

- There are no configurable parameters for Maglev load balancers.

{{< highlight yaml "hl_lines=2-2" >}}
    loadBalancerConfig:
      maglev: {}
{{< /highlight >}}



### Route Plugin Configuration

- Full specification

{{< highlight yaml "hl_lines=20-29" >}}
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: default
  namespace: gloo-system
spec:
  virtualHost:
    domains:
    - '*'
    name: gloo-system.default
    routes:
    - matcher:
        exact: /route1
      routeAction:
        single:
          upstream:
            name: default-session-affinity-app-80
            namespace: gloo-system
      routePlugins:
        lbHash:
          hashPolicies: # (1)
          - header: x-test-affinity
            terminal: true # (2)
          - header: origin # (3)
          - sourceIp: true # (4)
          - cookie: # (5)
              name: gloo
              path: /abc
              ttl: 1s # (6)
        prefixRewrite:
          prefixRewrite: /count
{{< /highlight >}}

##### Notes on hash policies

1. One or more `hashPolicies` may be specified.
2. Ordering of hash policies matters in that any hash policy can be `terminal`, meaning that if Envoy is able to create a hash key with the policies that it has processed up to and including that policy, it will ignore the subsequent policies. This can be used for implementing a content-contingent hashing policy optimization. For example, if a "x-unique-id" header is available, Envoy can save time by ignoring the later identifiers.
  - Optional, default: `false`
3. `header` policies indicate headers that should be included in the hash key.
4. The `sourceIp` policy indicates that the request's sourece IP address should be included in the hash key.
5. `cookie` policies indicate that the specified cookie should be included in the hash key.
  - `name`, required, identifies the cookie
  - `path`, optional, cookie path
  - `ttl`, optional, if set, Envoy will create the specified cookie, if it is not present on the request
6. Envoy can be configured to create cookies by setting the `ttl` parameter. If the specified cookie is not available on the request, Envoy will create it and add it to the response.
