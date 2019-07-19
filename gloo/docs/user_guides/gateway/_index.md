---
title: API Gateway
weight: 3
---


## The API Gateway pattern

With the API Gateway pattern, we are explicitly simplifying the calling of a group of APIs to emulate a cohesive API for an “application” for a specific set of users, clients, or consumers. As we use microservices to build our systems, the notion of “application” kind of disappears. The API Gateway pattern helps to restore this notion. The key here is the API gateway, when it’s implemented, becomes the API for clients and applications and is responsible for communicating with any backend APIs and other application network endpoints (those that don’t meet the aforementioned definition of API). Another term you may hear that represents the API gateway pattern is “backend for frontends” where “front end” can be literal front ends (UIs), mobile clients, IoT clients, or even other service/application developers.

## A developer's tool
An API gateway is much closer to the developers view of the world and is less concentrated on what ports or services are exposed for outside-the-cluster consumption. An API gateway mashes up calls to backends that may expose APIs, but may also talk to things less described as APIs such as RPC calls to legacy systems, calls with protocols that don’t fit the nice semblance of “REST” such as hacked together JSON over HTTP, gRPC, SOAP, GraphQL, websockets, and message queues. This type of gateway may also be called upon to do message-level transformation, complex routing, network resilience/fallbacks, and aggregation of responses.

## Fits a decentralized workflow
Since the API gateway is so closely related to the development of applications and services, we’d expect developers to be involved in helping to specify the APIs exposed by the API gateways, understanding any of the mashup logic involved, as well as need the ability to quickly test and make changes to this API infrastructure. We also expect operations or SRE to have some opinions about security, resiliency, and observability configuration for the API gateway. This level of infrastructure must also fit into the evolving, on-demand, self-service developer workflow. See the [GitOps model](../concepts/declarative_infrastructure_and_gitops) for more on that.

## Understanding Gloo API Gateway
Gloo API Gateway contains a robust set of features and is accessible using Gloo's own Custom-Resource based resources: `Upstreams` and `VirtualServices`.

`VirtualServices` provide the routing configuration to Gloo in the form of route tables. Each Virtual Service represents an ordered set of routes for a single set of domains.

`Upstreams` represent routable destinations in Gloo, similar to [`clusters` in Envoy terminology](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/cds.proto), except that Upstreams can be expressed as custom resources (stored in Kubernetes, Consul, or in YAML files).


Follow these guides to get started using Gloo Gateway:

{{% children description="true" %}}
