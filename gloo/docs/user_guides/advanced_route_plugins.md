---
title: Advanced Route Plugins
weight: 38
description: Advanced routing Plugins for Gloo.
---

Gloo uses a [Virtual Service]({{< ref "/v1/github.com/solo-io/gloo/projects/gateway/api/v1/virtual_service.proto.sk" >}})
Custom Resource (CRD) to allow users to specify one or more [Route]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#route" >}})
rules to handle as a group. This guide will discuss how to matched routes act upon requests. Please refer to the
[Advanced Route Matching]({{< ref "/user_guides/advanced_routing" >}}) guide for more information on how to pattern match
requests in routes, and [Route Action]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#routeaction" >}})
for more information on how to forward requests to upstream providers. This guide will discuss
[Route Plugins]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins.proto.sk#routeplugins" >}}) which
allow you to fine tune how requests and responses are handled.

## Base example

You can use the glooctl command line to provide you a template manifest that you can start editing. The `--dry-run` option
tells glooctl to NOT actually create the custom resource and instead output the custom resource manifest. This is a
great way to get an initial manifest template that you can edit and then `kubectl apply` later. For example, the
[`glooctl add route`]({{< ref "/cli/glooctl_add_route" >}}) command will generate a `VirtualService` resource if it
does not already exist, and it will add a route spec like the following which shows forwarding all requests to `/petstore`
to the upstream `default-petstore-8080` in the `gloo-system` namespace which will rewrite the matched query path with
the specified path to `prefixRewrite:`.

```shell
glooctl add route --dry-run \
  --name default \
  --path-prefix /petstore \
  --dest-name default-petstore-8080 \
  --dest-namespace gloo-system \
  --prefix-rewrite /api/pets
```

{{< highlight yaml "hl_lines=19-21" >}}
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  creationTimestamp: null
  name: default
  namespace: gloo-system
spec:
  virtualHost:
    domains:
    - '*'
    routes:
    - matcher:
        prefix: /petstore
      routeAction:
        single:
          upstream:
            name: default-petstore-8080
            namespace: gloo-system
      routePlugins:
        prefixRewrite:
          prefixRewrite: /api/pets
status: {}
{{< /highlight >}}

## Route Plugins

On any route, you can add any one of the following types of plugins.

* [`transformations`](#transformation)
* [`faults`](#faults)
* [`prefixRewrite`](#prefixrewrite)
* [`timeout`](#timeout)
* [`retries`](#retries)
* [`extensions`](#extensions)

### Transformation {#transformation}

Transformation can contain zero or one of the following:

* [`transformationTemplate`](#transformation_template)
* [`headerBodyTransform`](#header_body_transform)

#### Transformation Template {#transformation_template}

* `advancedTemplates` : influences how extractors are processed

* `extractors` : `map<string, `[`Extraction`]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins/transformation/transformation.proto.sk#extraction" >}})`>`

* `headers` : `map<string, `[`InjaTemplate`]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins/transformation/transformation.proto.sk#injatemplate" >}})`>`
for each header you want to add/replace, provide a specification as follows where `my-header` is the header name, and
`value-to-be` is a literal or [Inja Templates](https://github.com/pantor/inja)

    {{< highlight yaml "hl_lines=2-5" >}}
headers:
  my-header:
    text: value-to-be
  my-other-header:
    text: other-value-to-be
{{< /highlight >}}

And only one of the following.

* `body` : an [`InjaTemplate`]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins/transformation/transformation.proto.sk#injatemplate" >}})
used to process the body of the messages. Assumes the body is a JSON object.

    {{< highlight yaml "hl_lines=2" >}}
body:
    text: value-to-be
{{< /highlight >}}

* `passthrough` : the presence of this attribute `passthrough: {}` tells Gloo to transform the headers only and skip
any transformations on the body, which can be helpful for large body messages that you do not want to buffer.

* `mergeExtractorsToBody` : 

[Inja Templates](https://github.com/pantor/inja) give you a powerful way to process JSON formatted data. For example,
if you had a message body that contained the JSON `{ "name": "world" }` then the Inja template `Hello {{ name }}` would
become `Hello world`. The template variables, e.g., `{{ name }}`, is used as the key into a JSON object and is replaced
with the key's associated value.

#### Header Body Transform {#header_body_transform}

Specific to AWS Lambda Proxy Integration. Expects a message who's body is a json object which includes a `headers` and
a `body`, and it will transform this to a typical HTTP message with headers and body where you'd expect.

{{< highlight yaml "hl_lines=20-26" >}}
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
        prefix: /petstore
      routeAction:
        single:
          upstream:
            name: default-petstore-8080
            namespace: gloo-system
      routePlugins:
        transformations:
          requestTransformation:
            transformationTemplate:
              requestTransformation:
                transformationTemplate:
                  headers:
                    x-canary-foo:
                      text: foo-bar-v2
                    :path:
                      text: /v2/canary/feature
                passthrough: {}
{{< /highlight >}}

### Faults {#faults}

This can be used for testing the resilience of your services by intentionally injecting faults (errors and delays) into
a percentage of your requests.

Abort specifies the percentage of request to error out.

* `percentage` : (default: 0) float value between 0.0 - 100.0
* `httpStatus` : (default: 0) int value for HTTP Status to return, e.g., 503

Delay specifies the percentage of requests to delay.

* `percentage` : (default: 0) float value between 0.0 - 100.0
* `fixedDelay` : (default: 0) [Duration](https://developers.google.com/protocol-buffers/docs/reference/csharp/class/google/protobuf/well-known-types/duration)
value for how long to delay selected requests

{{< highlight yaml "hl_lines=20-26" >}}
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
        prefix: /petstore
      routeAction:
        single:
          upstream:
            name: default-petstore-8080
            namespace: gloo-system
      routePlugins:
        faults:
          abort:
            percentage: 2.5
            httpStatus: 503
          delay:
            percentage: 5.3
            fixedDelay: 5s
{{< /highlight >}}

### Prefix Rewrite {#prefixrewrite}

[PrefixRewrite]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins/transformation/prefix_rewrite.proto.sk#prefixrewrite" >}})
allows you to replace (rewrite) the matched request path with the specified value. Set to empty string (`""`) to remove matched request path.

### Timeout {#timeout}

The maximum [Duration](https://developers.google.com/protocol-buffers/docs/reference/csharp/class/google/protobuf/well-known-types/duration)
to try to handle the request, inclusive of error retries.

{{< highlight yaml "hl_lines=20" >}}
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
        prefix: /petstore
      routeAction:
        single:
          upstream:
            name: default-petstore-8080
            namespace: gloo-system
      routePlugins:
        timeout: 20s
        retries:
          retryOn: connect-failure
          numRetries: 3
          perTryTimeout: 5s
{{< /highlight >}}

### Retries {#retries}

Specifies the retry policy for the route where you can say for a specific error condition how many times to retry and
for how long to try.

* `retryOn` : specifies the condition under which to retry the forward request to the upstream. Same as [Envoy x-envoy-retry-on](https://www.envoyproxy.io/docs/envoy/latest/configuration/http_filters/router_filter#config-http-filters-router-x-envoy-retry-on).
* `numRetries` : (default: 1) optional attribute that specifies the allowed number of retries.
* `perTryTimeout` : optional attribute that specifies the timeout per retry attempt. Is of type [Google.Protobuf.WellKnownTypes.Duration](https://developers.google.com/protocol-buffers/docs/reference/csharp/class/google/protobuf/well-known-types/duration).

{{< highlight yaml "hl_lines=20-23" >}}
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
        prefix: /petstore
      routeAction:
        single:
          upstream:
            name: default-petstore-8080
            namespace: gloo-system
      routePlugins:
        retries:
          retryOn: connect-failure
          numRetries: 3
          perTryTimeout: 5s
{{< /highlight >}}

### Extensions {#extensions}