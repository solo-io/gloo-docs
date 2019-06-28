---
title: API Gateway
weight: 3
---

The API Gateway contains a robust set of features and is accessible using Gloo's own Custom-Resource based resources: `Upstreams` and `VirtualServices`.

`VirtualServices` provide the routing configuration to Gloo in the form of route tables. Each Virtual Service represents an ordered set of routes for a single set of domains.

`Upstreams` represent routable destinations in Gloo, similar to [`clusters` in Envoy terminology](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/cds.proto), except that Upstreams can be expressed as custom resources (stored in Kubernetes, Consul, or in YAML files).


Follow these guides to get started using Gloo Gateway:

{{% children description="true" %}}
