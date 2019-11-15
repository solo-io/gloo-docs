---
menuTitle: Configuring TLS
title: Configuring Downstream and Upstream TLS
weight: 11
description: Configure Gloo to serve and terminate TLS to downstream clients, as well as initiate upstream connections using upstream TLS.
---

Gloo can perform *TLS termination* for downstream clients, unencrypting traffic arriving from downstream clients. 

Gloo is also capable of loading client certificates to perform mutual TLS with an *upstream server* which is already serving TLS.

For downstream TLS termination, [see the guide on setting up Server TLS]({{< ref "/gloo_routing/tls/server_tls">}})

For upstream TLS connections, [see the documentation on setting up Client TLS]({{< ref "/gloo_routing/tls/client_tls">}})

