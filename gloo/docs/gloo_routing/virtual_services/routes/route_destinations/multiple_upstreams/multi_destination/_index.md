---
title: Multi Destinations
weight: 10
description: This is where multiple upstreams are configured on a route, with weights associated with them. 
---

The [MultiDestination]({{% ref "/api/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#multidestination" %}})
has an array of one or more [WeightedDestination]({{% ref "/api/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#weighteddestination" %}})
specs that are a single destination plus a `weight`. The weight is the percentage of request traffic forwarded to that
destination where the percentage is: `weight` divided by sum of all weights in `MultiDestination`.

Here's an example to help make this more concrete. Assuming we've got two versions of a service - `default-myservice-v1-8080`
and `default-myservice-v2-8080` - and we want to route 10% of request traffic to `default-myservice-v2-8080` as part of a
Canary deploy, i.e., route a small portion of traffic to a new version to make sure new version works in the service before
decommissioning the original version. Here's what a route would look like with 90% of traffic going to v1 and 10% to v2.

{{< highlight yaml "hl_lines=5-16" >}}
routes:
- matcher:
    prefix: /myservice
  routeAction:
    multi:
      destinations:
      - weight: 9
        destination:
          upstream:
            name: default-myservice-v1-8080
            namespace: gloo-system
      - weight: 1
        destination:
          upstream:
            name: default-myservice-v2-8080
            namespace: gloo-system
{{< /highlight >}}
