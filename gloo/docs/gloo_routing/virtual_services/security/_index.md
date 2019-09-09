---
title: Authentication (Enterprise)
weight: 30
description: Gloo has a few different options for Authentication; choose the one that best suits your use case.
---

#### Why Authenticate in API Gateway Environments
API Gateways act as a control point for the outside world to access the various application services 
(monoliths, microservices, serverless functions) running in your environment. In microservices or hybrid application 
architecture, any number of these workloads will need to accept incoming requests from external end users (clients). 
Incoming requests can be treated as anonymous or authenticated and depending on the service, you may want to 
establish and validate who the client is, the service they are requesting and define any access or traffic 
control policies.

#### Authentication in Gloo
Gloo Enterprise provides a variety of authentication options to meet the needs of your environment. They range from 
supporting basic use cases to the complex and fine grained secure access control. Architecturally, Gloo uses an 
auth server to verify the user and their access. Gloo provides an auth server that can support OpenID Connect 
and basic use cases but also allows you to use your own auth server to implement custom logic. 

##### Sidecar mode
By default, Gloo's built-in Auth Server is deployed as its own Kubernetes pod. This means that, in order to 
authenticate a request, Gloo (which runs in a separate pod) needs to communicate with the service over the network. 
In case you deem this overhead not to be acceptable for your use case, you can deploy the server in **sidecar mode**.

In this configuration, the Ext Auth server will run as an additional container inside the `gateway-proxy` pod(s) that run 
Gloo's Envoy instance(s) and communication with Envoy will occur via Unix Domain Sockets instead of TCP. This cuts out 
the overhead associated with the TCP protocol and can provide huge performance benefits (40%+ in some benchmarks).

You can activate this mode by [installing Gloo with Helm]({{< ref "installation/enterprise#installing-on-kubernetes-with-helm" >}})
and providing the following value override:

| option                                                    | type     | description                                                                                                                                                                                                                                                    |
| --------------------------------------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| global.extensions.extAuth.envoySidecar                    | bool     | Deploy ext-auth as a sidecar to Envoy instances. Communication occurs over Unix Domain Sockets instead of TCP. Default is `false` |

For more details, check out the individual guides for each of the Gloo auth modules:

{{% children description="true" %}}
