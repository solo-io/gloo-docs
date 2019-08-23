---
title: External Auth
weight: 1
description: Authenticating Virtual Services with Gloo's built-in Auth server, which supports several types of auth. 	
---

Enterprise Gloo comes with a built-in authentication server, and several different forms of authentication are 
supported out of the box, which can be configured per **VirtualService**. 

The external-auth service itself can be configured via helm:

| option                                                    | type     | description                                                                                                                                                                                                                                                    |
| --------------------------------------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| global.extensions.extAuth.envoySidecar                    | bool     | deploy ext-auth in the gateway-proxy pod, as a sidecar to envoy. communicates over unix domain socket instead of TCP. default is `false` |

Deploying external auth as an envoy sidecar over a unix domain socket can provide huge perfomance (40%+ in some benchmarks)
benefits since it cuts out TCP overhead from its communications.

{{% children description="true" %}}
