---
title: "Developer Guides"
weight: 100
---

## Intro


Gloo invites invites developers to extend Gloo's functionality and adapt to new use cases via the addition of plugins. 

Gloo's plugin based architecture makes it easy to extend functionality in a variety of areas:

- [Gloo's API](https://github.com/solo-io/gloo/tree/master/projects/gloo/api/v1): extensible through the use of [Protocol Buffers](https://developers.google.com/protocol-buffers/) along with [Solo-Kit](https://github.com/solo-io/solo-kit)
- [Service Discovery Plugins](https://github.com/solo-io/gloo/blob/master/projects/gloo/pkg/discovery/discovery.go#L21): automatically discover service endpoints from catalogs such as [Kubernetes](https://github.com/solo-io/gloo/tree/master/projects/gloo/pkg/plugins/kubernetes) and [Consul](https://github.com/solo-io/gloo/tree/master/projects/gloo/pkg/plugins/consul)
- [Function Discovery Plugins](https://github.com/solo-io/gloo/blob/master/projects/discovery/pkg/fds/interface.go#L31): annotate services with information discovered by polling services directly (such as OpenAPI endpoints and gRPC methods).
- [Routing Plugins](https://github.com/solo-io/gloo/blob/master/projects/gloo/pkg/plugins/plugin_interface.go#L53): customize what happens to requests when they match a route or virtual host
- [Upstream Plugins](https://github.com/solo-io/gloo/blob/master/projects/gloo/pkg/plugins/plugin_interface.go#L44): customize what happens to requests when they are routed to a service
- **Operators for Configuration**: Gloo exposes its intermediate language for proxy configuration via the [`gloo.solo.io/Proxy`](https://gloo.solo.io/api/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk/#proxy) Custom Resource, allowing operators to leverage Gloo for multiple use cases. The [Gloo Gateway](https://github.com/solo-io/gloo/tree/master/projects/gateway) and [Sqoop](https://github.com/solo-io/sqoop) provide API Gateway and GraphQL Server functionality respectively, without needing to run in the same process (or even the same container) as Gloo.

## Gloo API Concepts


* [v1.Proxies]({{< ref "/api/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk.md">}}) provide the routing configuration which Gloo will translate and apply to Envoy.
* [v1.Upstreams]({{< ref "/api/github.com/solo-io/gloo/projects/gloo/api/v1/upstream.proto.sk.md">}}) describe routable destinations for Gloo.

* **Proxies** represent a unified configuration to be applied to one or more instances of a proxy. You can think of the proxy of as tree like such:

        proxy
        ├─ bind-address
        │  ├── domain-set
        │  │  ├── /route
        │  │  ├── /route
        │  │  ├── /route
        │  │  └── tls-config
        │  └── domain-set
        │     ├── /route
        │     ├── /route
        │     ├── /route
        │     └── tls-config
        └─ bind-address
           ├── domain-set
           │  ├── /route
           │  ├── /route
           │  ├── /route
           │  └── tls-config
           └── domain-set
              ├── /route
              ├── /route
              ├── /route
              └── tls-config

  A single proxy CRD contains all the configuration necessary to be applied to an instance of Envoy. In the Gloo system, Proxies are treated as an intermediary representation of config, while user-facing config is imported from simpler, more opinionated resources such as the [gateway.VirtualService]({{< ref "/api/github.com/solo-io/gloo/projects/gateway/api/v1/virtual_service.proto.sk.md">}}) or [Kubernetes Ingress objects](https://kubernetes.io/docs/concepts/services-networking/ingress/).
  
  For this reason, a standard Gloo deployment contains one or more controllers which programmatically generate and write these CRDs to provide simpler, use-case specific APIs such as API Gateway and Ingress. [Sqoop](https://sqoop.solo.io/) is an advanced controller which creates routing configuration for Gloo from [**GraphQL Schemas**](https://graphql.org/). 
  
  [Click here for a tutorial providing a simple example utilizing this lower-level Proxy API](example-proxy-controller). This tutorial will walk you through building a Kubernetes controller to automatically configure Gloo without any user interaction](example-proxy-controller.go).

* **Upstreams** represent destinations for routing requests in Gloo. Routes in Gloo specify one or more Upstreams (by name) as their destination. Upstreams have a `type` which is provided in their `upstreamSpec` field. Each type of upstream corresponds to an **Upstream Plugin**, which tells Gloo how to translate upstreams of that type to Envoy clusters. When a route is declared for an upstream, Gloo invokes the corresponding plugin for that type 


## Guides

This Section includes the following developer guides:

{{% children description="true" %}}

> Note: the Controller tutorial does not require modifying any Gloo code.

