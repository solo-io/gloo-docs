---
title: Advanced Route Matching
weight: 35
description: Advanced routing matching rules for Gloo.
---

Gloo uses a `VirtualService` CRD to allow users to specify one or more route rules to handle as a group (Virtual Service).
This guide will discuss how to configure Gloo to handle various routing scenarios. These are examples of how
to use the [Route Matcher]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#matcher" %}}).

To give you some context, Gloo [Virtual Services]({{% ref "/v1/github.com/solo-io/gloo/projects/gateway/api/v1/virtual_service.proto.sk#VirtualService" %}}) contain zero or more [Route]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#route" %}}) objects.
Each [Route]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#route" %}}) contains a
[Matcher]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#matcher" %}}), which is the main
way that Gloo uses to determine (or match) if a request coming into the Gloo gateway proxy should be acted on, i.e.,
forwarded to an upstream. This guide will primarily focus on the details of configuring a
[Matcher]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#matcher" %}}).

In most cases, you can use the `glooctl create virtualservice --name <your service name>` command ([doc here]({{% ref "/cli/glooctl_create_virtualservice" %}}))
to create this resource initially. For example,

```shell
glooctl create virtualservice --name default
kubectl get virtualservices default --namespace gloo-system --output yaml
```

```yaml
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  creationTimestamp: "2019-03-26T20:17:40Z"
  generation: 2
  name: default
  namespace: gloo-system
  resourceVersion: "8904"
  selfLink: /apis/gateway.solo.io/v1/namespaces/gloo-system/virtualservices/default
  uid: 34c5ebc9-5004-11e9-a339-62377b03fa19
spec:
  virtualHost:
    domains:
    - '*'
status:
  reported_by: gateway
  state: 1
  subresource_statuses:
    '*v1.Proxy gloo-system gateway-proxy':
      reported_by: gloo
      state: 1
```

The following are the different aspects of the request that you can match against a route rule. Each aspect is `AND`
with others, i.e., all aspects must test `true` for the route to match and the specified route action to be taken.

* [Path Matching](#path)
* [Header Based](#header)
* [Query Parameter](#query)
* [HTTP Method](#method)

## Path Matching {#path}

There are three options to do HTTP path matching. You can specify only one of the following three options within any given
route matcher spec. Note, `routes` is an array of [gloo.solo.io.Route]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#route" %}})
objects, and each `route` has one [`matcher`]({{% ref "/user_guides/gateway/configuring_route_options/advanced_routing#path" %}}) that can contain one of
the path matchers: `prefix`, `exact`, or `regex`.

* `prefix` - match if the beginning path of request path matches specified path.
* `exact` - match if request path matches specified path exactly.
* `regex` - match if the specified regular expression matches. More details in [Matcher doc]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#matcher" %}})
and [Envoy doc](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/route/route.proto#envoy-api-msg-route-routematch).
Full details of regular expression grammar are at <https://en.cppreference.com/w/cpp/regex/ecmascript>.

Given the following example virtual service using the `prefix` matching against `/hello` path. For this example,
any request to `/hello`, `/hello123`, or `/hello/other/stuff` will all match this route rule.

{{< highlight yaml "hl_lines=12" >}}
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: default
  namespace: gloo-system
spec:
  virtualHost:
    domains:
    - '*'
    routes:
    - matcher:
        prefix: /hello
      routeAction:
        single:
          upstream:
            name: default-hello-8080
            namespace: gloo-system
{{< /highlight >}}

To create the above route using `glooctl`, you can do the following.

```shell
glooctl add route \
    --name default \
    --path-prefix /hello \
    --dest-name default-hello-8080
```

To test you can use `glooctl proxy url` to get the Gloo gateway base URL, and then add the path.

```shell
curl $(glooctl proxy url)/hello
```

## Header Based {#header}

Here's how you specify request headers that must be present, and have a matching value, to match the given route rule.
You can specify zero or more [Header Matcher]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#headermatcher" %}})
for each route. Each header matcher has three attributes: `name`, `value`, and `regex`.

* `name` - the name of the request header. Note: Gloo/Envoy use HTTP/2 so if you want to match against HTTP/1 `Host`,
use `:authority` (HTTP/2) as the name instead.
* `regex` - boolean (true|false) defaults to `false`. Indicates how to interpret the `value` attribute:
  * `false` (default) - treat `value` field as an [Envoy exact_match](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/route/route.proto#envoy-api-field-route-headermatcher-exact-match)
  * `true` - treat `value` field as a regular expression as defined by [Envoy regex_match](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/route/route.proto#envoy-api-field-route-headermatcher-regex-match)
* `value`
  * If no value is specified, then the presence of the header in the request with any value will match
([Envoy present_match](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/route/route.proto#envoy-api-field-route-headermatcher-present-match))
  * If present, then field value interpreted based on the value of `regex` field

{{< highlight yaml "hl_lines=12-15" >}}
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: default
  namespace: gloo-system
spec:
  virtualHost:
    domains:
    - '*'
    routes:
    - matcher:
        headers:
        - name: foo
          regex: false
          value: bar
        prefix: /hello
      routeAction:
        single:
          upstream:
            name: default-hello-8080
            namespace: gloo-system
{{< /highlight >}}

To create the above route using `glooctl`, you can do the following. Multiple `--headers` can be specified. The CLI will
try to inspect the provided value to guess if its a regular expression (or not), and set the `regex` field accordingly.

```shell
glooctl add route \
    --name default \
    --header "foo=bar" \
    --path-prefix /hello \
    --dest-name default-hello-8080
```

To test you can use `glooctl proxy url` to get the Gloo gateway base URL, and then add the path.

```shell
curl --header "foo: bar" $(glooctl proxy url)/hello
```

## Query Parameter {#query}

Here's how you specify request query parameters that must be present, and have a matching value, to match the given
route rule. You can specify zero or more [Query Parameter Matcher]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#queryparametermatcher" %}})
for each route. Each query param matcher has three attributes: `name`, `value`, and `regex`.

* `name` - the name of the query parameter
* `regex` - boolean (true|false) defaults to `false`. Indicates how to interpret the `value` attribute:
  * `false` (default) - will match if `value` exactly matches query parameter value
  * `true` - treat `value` field as a regular expression
* `value`
  * If no value is specified, then the presence of the query parameter in the request with any value will match
  * If present, the `value` field will be interpreted based on the value of `regex` field

For example, the following will match requests who's path starts with `/hello`, and has the query parameter `?foo=bar`.

{{< highlight yaml "hl_lines=12-15" >}}
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: default
  namespace: gloo-system
spec:
  virtualHost:
    domains:
    - '*'
    routes:
    - matcher:
        queryParameters:
        - name: foo
          regex: false
          value: bar
        prefix: /hello
      routeAction:
        single:
          upstream:
            name: default-hello-8080
            namespace: gloo-system
{{< /highlight >}}

To test you can use `glooctl proxy url` to get the Gloo gateway base URL, and then add the path.

```shell
curl "$(glooctl proxy url)/hello?foo=bar"
```

## HTTP Method {#method}

You can also create route rules based on the request HTTP method, e.g. GET, POST, DELETE, etc. You can specify one or
more HTTP Methods to match against, and if any one of those method verbs is present, the request will match, that is
Gloo will conditional OR the match for HTTP Method. Note: since Gloo/Envoy is based on HTTP/2, this gets translated
into a header value match against the HTTP/2 `:method` header, which [by spec](https://http2.github.io/http2-spec/#HttpRequest)
includes all of the HTTP/1 verbs.

For example, the following will match requests who's path starts with `/hello`, and has the HTTP Method `GET` or `POST`.

{{< highlight yaml "hl_lines=12-14" >}}
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: default
  namespace: gloo-system
spec:
  virtualHost:
    domains:
    - '*'
    routes:
    - matcher:
        methods:
        - GET
        - POST
        prefix: /hello
      routeAction:
        single:
          upstream:
            name: default-hello-8080
            namespace: gloo-system
{{< /highlight >}}

To create the above route using `glooctl`, you can do the following. Multiple `--method` options can be specified, and
the result matches if any one of the methods is present in the request.

```shell
glooctl add route \
    --name default \
    --method GET \
    --method POST \
    --path-prefix /hello \
    --dest-name default-hello-8080
```

To test you can use `glooctl proxy url` to get the Gloo gateway base URL, and then add the path.

```shell
curl -X GET $(glooctl proxy url)/hello
```
