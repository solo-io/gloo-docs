---
title: Prefix Rewrite
weight: 30
description: Prefix-rewriting when routing to upstreams
---

[PrefixRewrite]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins/transformation/prefix_rewrite.proto.sk#prefixrewrite" >}})
allows you to replace (rewrite) the matched request path with the specified value. To remove a prefix, you may need to configure 1-2 routes to get your desired result with a `prefixRewrite: "/"` setting. That is, if you wanted to match a route prefix of `/foo` and then remove `/foo` before sending to upstream, you would need to define two (2) routes to achieve this. First create a route matcher for `prefix: /foo/` with a `prefixRewrite: /`, and the create a second route matcher for `prefix: /foo` with a `prefixRewrite: /`. Order matters for route matching. The `/foo/` => `/` rewrite "fixes" the `:path //` problem that occurs with a single route matcher of `/foo`. See [Envoy prefix rewrite doc](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/route/route.proto.html#envoy-api-field-route-routeaction-prefix-rewrite) for more details.

{{% notice warning %}}
Setting prefixRewrite to "" is ignored. Its currently interpreted the same as if you did not provide any value at all, i.e., do NOT rewrite the path.
{{% /notice %}}
