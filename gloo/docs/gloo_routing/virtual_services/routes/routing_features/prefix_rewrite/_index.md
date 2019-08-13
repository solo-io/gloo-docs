---
title: Prefix Rewrite
weight: 30
description: Prefix-rewriting when routing to upstreams
---

[PrefixRewrite]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins/transformation/prefix_rewrite.proto.sk#prefixrewrite" >}})
allows you to replace (rewrite) the matched request path with the specified value. Set to empty string (`""`) to remove
the matched request path.