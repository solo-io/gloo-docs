---
title: Filter Order
weight: 110
description: Details on how Gloo orders Envoy filters.
---

## Introduction

Gloo exposes and manages several Envoy filters.
For certain filters, relative order is irrelevant.
For others, filter order is critical to ensuring proper behavior.
This document show the order of filters as used in Open Source Gloo and Enterprise Gloo.

## Summary

Gloo orders Envoy's HTTP filters (which are themselves members of the "envoy.http_connection_manager" filter) in the following order with 
_[filter stage, filter stage weight, and filter name]_ shown for reference.

- Fault Injection [`FaultStage, 0, envoy.fault`]
- CORS [`CorsStage, 0, envoy.cors`]
- WAF (Enterprise) [`WafStage, 0, io.solo.filters.http.modsecurity`]
- ExtAuth - Sanitize (Enterprise) [`AuthNStage, -1, io.solo.filters.http.sanitize`]
- ExtAuth - AuthZ (Enterprise) [`AuthNStage, 0, envoy.ext_authz`]
- JWT (Enterprise) [`AuthNStage, 0, io.solo.filters.http.solo_jwt_authn`]
- RBAC (Enterprise) [`AuthZStage, 0, envoy.filters.http.rbac`]
- gRPC Web [`AuthZStage, 1, envoy.grpc_web`]
- Health Check [`AuthZStage, 1, envoy.health_check`]
- Transformation [`AuthZStage, 1, io.solo.transformation`]
- Rate Limit (Enterprise) [`RateLimitStage, 0, envoy.rate_limit`]
- gRPC [`OutAuthStage, -1, envoy.grpc_json_transcoder`]
- AWS Lambda [`OutAuthStage, -1, io.solo.aws_lambda`]
- Router [`RouteStage, 0, envoy.router`]

<!--
Note: hiding this field, will surface for clarification as needed
- Translator  [`AuthZStage`, 1, "envoy.http_connection_manager"]
-->




## Filter order management details

Gloo resolves filter order according to filter stage, relative weight, and filter name.
The ordering method is illustrated in the diagram below.
Filters are ordered by their filter stage membership, top to bottom, then by their weight, increasing from left to right, and lastly by their name.
Note that it is possible to have multiple filters with the same stage, weight, and name however the order will be undefined.

![Filter stage ordering diagram](/img/filter_stage_order.png)

Gloo uses an extensible [1] filter ordering system to manage the order of Envoy filters.
Filters are placed relative to a list of `WellKnownFilterStage`.

The list of `WellKnownFilterStage`s includes:
```go
FaultStage     // Fault injection // First Filter Stage
CorsStage      // Cors stage
WafStage       // Web application firewall stage
AuthNStage     // Authentication stage
AuthZStage     // Authorization stage
RateLimitStage // Rate limiting stage
AcceptedStage  // Request passed all the checks and will be forwarded upstream
OutAuthStage   // Add auth for the upstream (i.e. aws λ)
RouteStage     // Request is going to upstream // Last Filter Stage
```

The placement of each particular filter is defined relative to a given `WellKnownFilterStage`, by a certain weight.
```go
RelativeToStage(wellKnown WellKnownFilterStage, weight int)
```

Ordering is evaluated by first comparing the `WellKnownFilterStage`, then the `weight`, and, as a tie breaker, the filter's name.
To give a few examples:

- All filters defined relative to the `CorsStage` will come after all filters defined relative to the `FaultStage` and before all filters defined relative to the `WafStage`.
- If two filters are defined relative to the same stage, the filter with the lower weight will come first.
- If two filters are defined relative to the same stage and have the same weight, the filter with an alpha-numerically lesser name will come first.

#### Footnotes

1. At the moment, Gloo must be recompiled to alter filter ordering.
In the future, this capability may be exposed as a configuration option.
