---
title: Authentication
weight: 3
description: Authentication features of Gloo Enterprise
---
**Why Authenticate in API Gateway Environments**
API Gateways act as a control point for the outside world to access the various application services (monoliths, microservices, serverless functions) running in your environment. In microservices or hybrid application architecture, any number of these workloads will need to accept incoming requests from external end users (clients). Incoming requests can be treated as anonymous or authenticated and depending on the service, you may want to establish and validate who the client is, the service they are requesting and define any access or traffic control policies.

**Authentication in Gloo**
Gloo Enterprise provides a variety of authentication options to meet the needs of your environment. They range from supporting basic use cases to the complex and fine grained secure access control. Architecturally, Gloo uses an auth server to verify the user and their access. Gloo provides an auth server that can support OpenID Connect and basic use cases but also allows you to use your own auth server to implement custom logic. 

Guides for the various authentication options for Gloo Enterprise.

{{% children description="true" %}}
