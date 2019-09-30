---
title: API Reference
weight: 100
---

### API Reference for Gloo, The Hybrid Application Gateway

API Version: `gloo.solo.io.v1`

Gloo is a high-performance, plugin-extendable, platform-agnostic API Gateway built on top of Envoy. Gloo is designed for 
microservice, monolithic, and serverless applications. By employing function-level routing, Gloo can completely decouple 
client APIs from upstream APIs at the routing level. Gloo serves as an abstraction layer between clients and upstream services, allowing front-end teams to work independently of teams developing the microservices their apps connect to.


### API Resources:
- Overview
  - [Upstreams](github.com/solo-io/gloo/projects/gloo/api/v1/upstream.proto.sk#Upstream)
  - [Virtual Services](github.com/solo-io/gloo/projects/gateway/api/v1/virtual_service.proto.sk#VirtualService)
  - [Secrets](github.com/solo-io/gloo/projects/gloo/api/v1/secret.proto.sk#Secret)
  - [Artifacts](github.com/solo-io/gloo/projects/gloo/api/v1/artifact.proto.sk#Artifact)
  - [Ingress](github.com/solo-io/gloo/projects/ingress/api/v1/ingress.proto.sk#Ingress)
  - [KubeService](github.com/solo-io/gloo/projects/ingress/api/v1/service.proto.sk#KubeService)
- [Plugins](github.com/solo-io/gloo/projects/gloo/api/v1/plugins.proto.sk/)
  - [Transformation](github.com/solo-io/gloo/projects/gloo/api/v1/plugins/transformation/transformation.proto.sk/)
  - [Transformation Parameters](github.com/solo-io/gloo/projects/gloo/api/v1/plugins/transformation/parameters.proto.sk/)
  - [Transformation Prefix Rewrite](github.com/solo-io/gloo/projects/gloo/api/v1/plugins/transformation/prefix_rewrite.proto.sk/)
  - [Service Spec](github.com/solo-io/gloo/projects/gloo/api/v1/plugins/service_spec.proto.sk/)
  - [AWS](github.com/solo-io/gloo/projects/gloo/api/v1/plugins/aws/aws.proto.sk/)
  - [Azure](github.com/solo-io/gloo/projects/gloo/api/v1/plugins/azure/azure.proto.sk/)
  - [Rest](github.com/solo-io/gloo/projects/gloo/api/v1/plugins/rest/rest.proto.sk/)
  - [Static](github.com/solo-io/gloo/projects/gloo/api/v1/plugins/static/static.proto.sk/)
  - [Consul](github.com/solo-io/gloo/projects/gloo/api/v1/plugins/consul/consul.proto.sk/)
  - [Kubernetes](github.com/solo-io/gloo/projects/gloo/api/v1/plugins/kubernetes/kubernetes.proto.sk/)
  - [gRPC](github.com/solo-io/gloo/projects/gloo/api/v1/plugins/grpc/grpc.proto.sk/)
  - [Fault Injection](github.com/solo-io/gloo/projects/gloo/api/v1/plugins/faultinjection/fault.proto.sk/)
  - [External Auth (Enterprise)](github.com/solo-io/gloo/projects/gloo/api/v1/enterprise/plugins/extauth/v1/extauth.proto.sk/)
  - [Rate Limiting (Enterprise)](github.com/solo-io/gloo/projects/gloo/api/v1/enterprise/plugins/ratelimit/ratelimit.proto.sk/)
- Core
  - [Metadata](github.com/solo-io/solo-kit/api/v1/metadata.proto.sk/)
  - [Status](github.com/solo-io/solo-kit/api/v1/status.proto.sk/)
  - [ResourceRef](github.com/solo-io/solo-kit/api/v1/ref.proto.sk/)
- Advanced
  - [Settings](github.com/solo-io/gloo/projects/gloo/api/v1/settings.proto.sk/)
  - [Gateways](github.com/solo-io/gloo/projects/gateway/api/v1/gateway.proto.sk/)
  - [Proxies](github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk/)

<!-- Start of HubSpot Embed Code -->
<script type="text/javascript" id="hs-script-loader" async defer src="//js.hs-scripts.com/5130874.js"></script>
<!-- End of HubSpot Embed Code -->

