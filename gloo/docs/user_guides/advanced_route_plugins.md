---
title: Advanced Route Plugins
menuTitle: Advanced Route Plugins
weight: 38
description: Advanced routing Plugins for Transformation, retries, timeouts, and other fine grained controls.
---

Gloo uses a [Virtual Service]({{< ref "/v1/github.com/solo-io/gloo/projects/gateway/api/v1/virtual_service.proto.sk" >}})
Custom Resource (CRD) to allow users to specify one or more [Route]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#route" >}})
rules to handle as a group. This guide will discuss plugins that can affect how matched routes act upon requests. Please
refer to the [Advanced Route Matching]({{< ref "/user_guides/advanced_routing" >}}) guide for more information on how to
pattern match requests in routes and [Route Action]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#routeaction" >}})
for more information on how to forward requests to upstream providers. This guide will discuss
[Route Plugins]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins.proto.sk#routeplugins" >}}) which
allow you to fine-tune how requests and responses are handled.

## Base example

You can use the glooctl command line to provide you a template manifest that you can start editing. The `--dry-run` option
tells glooctl to NOT create the custom resource and instead output the custom resource manifest. This is a
great way to get an initial manifest template that you can edit and then `kubectl apply` later. For example, the
[`glooctl add route`]({{< ref "/cli/glooctl_add_route" >}}) command will generate a `VirtualService` resource if it
does not already exist, and it will add a route spec like the following which shows forwarding all requests to `/petstore`
to the upstream `default-petstore-8080` which will rewrite the matched query path with the specified path by `prefixRewrite`.

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
  name: 'default'
  namespace: 'gloo-system'
spec:
  virtualHost:
    domains:
    - '*'
    routes:
    - matcher:
        prefix: '/petstore'
      routeAction:
        single:
          upstream:
            name: 'default-petstore-8080'
            namespace: 'gloo-system'
      routePlugins:
        prefixRewrite:
          prefixRewrite: '/api/pets'
status: {}
{{< /highlight >}}

## Route Plugins

On any route, you can add each of the following types of plugins. Specifying a route plugin adds or modifies the behavior
on an Envoy filter that is processing the request and response traffic.

{{% notice note %}}
Be aware that adding plugins can have a negative impact on the request latency so good idea to do some extra testing to
validate latency impacts.
{{% /notice %}}

* [transformations](#route_transformations)
* [faults](#faults)
* [prefixRewrite](#prefixrewrite)
* [timeout](#timeout)
* [retries](#retries)
* [extensions](#extensions)

### Route Transformations {#route_transformations}

Within a route, you can have [RouteTransformations]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins/transformation/transformation.proto.sk#routetransformations" >}})
for either or both of the following.

* [`requestTransformation`](#transformation) - transform the request message *before* sending to the upstream destination
* [`responseTransformation`](#transformation) - transform the response message from the upstream destination

Both of these are of type [Transformation]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins/transformation/transformation.proto.sk#transformation" >}})
as the following describes.

#### Transformation {#transformation}

[Transformation]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins/transformation/transformation.proto.sk#transformation" >}})
can contain zero or one of the following:

* [`transformationTemplate`](#transformation_template)
* [`headerBodyTransform`](#header_body_transform)

For example, to have a transformation template for the request and header body transform for the response, the following
is a snippet of the manifest.

{{< highlight yaml "hl_lines=19-23" >}}
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: 'default'
  namespace: 'gloo-system'
spec:
  virtualHost:
    domains:
    - '*'
    routes:
    - matcher:
        prefix: '/petstore'
      routeAction:
        single:
          upstream:
            name: 'default-petstore-8080'
            namespace: 'gloo-system'
      routePlugins:
        transformations:
          requestTransformation:
            transformationTemplate: { ... }
          responseTransformation:
            headerBodyTransform: {}
{{< /highlight >}}

##### Header Body Transform {#header_body_transform}

Specific to AWS Lambda Proxy Integration. AWS Lambda only permits functions to return JSON responses and this
transformation can be used to unwrap that JSON body to provide a typical HTTP response that you're more likely expecting.
This transform expects a message who's body is a JSON object that includes `headers` and `body` keys, and this transform
will transform this to a typical HTTP message with headers and body where you'd expect.

{{< highlight yaml "hl_lines=21" >}}
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: 'default'
  namespace: 'gloo-system'
spec:
  virtualHost:
    domains:
    - '*'
    routes:
    - matcher:
        prefix: '/petstore'
      routeAction:
        single:
          upstream:
            name: 'default-petstore-8080'
            namespace: 'gloo-system'
      routePlugins:
        transformations:
          responseTransformation:
            headerBodyTransform: {}
{{< /highlight >}}

##### Transformation Template {#transformation_template}

[TransformationTemplate]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins/transformation/transformation.proto.sk#transformationtemplate" >}})
provide advanced capabilities to modify the message's headers and body.

* `advancedTemplates` : (default `false`) if `true`, extractor values are NOT automatically merged into JSON body object

* `extractors` : `map<string, `[`Extraction`]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins/transformation/transformation.proto.sk#extraction" >}})`>`
these allow you to create a named variable based on a [regular expression](https://en.cppreference.com/w/cpp/regex/regex_match)
applied to a specified header. It is expected that you are extracting a portion of the header value, and that should be
indicated by using regular expression groups to capture the desired portion. For example, if we want to extract from
the response the minutes from the `date` header (e.g., `Thu, 04 Apr 2019 20:04:13 GMT`) we could use the following
extractor to map that value to `foo`. In this example, the `regex` has multiple groups, and we can use the `subgroup`
which capture group to return. Note: `subgroup` is 1-based.

    {{< highlight yaml "hl_lines=5-9" >}}
routePlugins:
  transformations:
    responseTransformation:
      transformation_template:
        extractors:
          foo:
            header: 'date'
            regex: '\w*, (.+):(.+):(.+) GMT'
            subgroup: 2
{{< /highlight >}}

* `headers` : `map<string, `[`InjaTemplate`]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins/transformation/transformation.proto.sk#injatemplate" >}})`>`
for each header you want to add/replace, provide a specification as follows where `my-header` is the header name, and
`value-to-be` is an [Inja Templates](https://github.com/pantor/inja/tree/74ad4281edd4ceca658888602af74bf2050107f0).
More details on using Inja Templates shortly.

    {{< highlight yaml "hl_lines=2-5" >}}
headers:
  my-header:
    text: 'value-to-be'
  my-other-header:
    text: 'other-value-to-be'
{{< /highlight >}}

And the Transformation Template can have only one of the following.

* `body` : an [`InjaTemplate`]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins/transformation/transformation.proto.sk#injatemplate" >}})
used to process the body of the messages. Assumes the body is a JSON object.

    {{< highlight yaml "hl_lines=2" >}}
body:
  text: 'value-to-be'
{{< /highlight >}}

* `passthrough` : the presence of this attribute, e.g., `passthrough: {}`, tells Gloo to transform the headers only and
skip any transformations on the body, which can be helpful for large body messages that you do not want to buffer.

* `mergeExtractorsToBody` : the presence of this attribute, e.g., `mergeExtractorsToBody: {}`, tells Gloo to merge all
of the extractor values into the JSON object, using the extractor names as JSON keys, and the whole JSON instance
replaces the message body contents.

##### InjaTemplate {#inja_template}

[Inja Templates](https://github.com/pantor/inja/tree/74ad4281edd4ceca658888602af74bf2050107f0) give you a powerful way
to process JSON formatted data. For example, if you had a message body that contained the JSON `{ "name": "world" }`
then the Inja template `Hello {{ name }}` would become `Hello world`. The template variables, e.g., `{{ name }}`, is
used as the key into a JSON object and is replaced with the key's associated value.

Gloo adds two additional functions that can be used within templates.

* `header` - returns the value of the specified header name, e.g., `{{ header("date") }}`
* `extraction` - returns the value of the specified extractor name, e.g. `{{ extraction("date") }}`. Only needed when
`advancedTemplates` is set to `true`, otherwise extractor values are available in the templates using their name as key

{{< highlight yaml "hl_lines=20-30" >}}
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: 'default'
  namespace: 'gloo-system'
spec:
  virtualHost:
    domains:
    - '*'
    name: 'gloo-system.default'
    routes:
    - matcher:
        prefix: '/'
      routeAction:
        single:
          upstream:
            name: 'jsonplaceholder-80'
            namespace: 'gloo-system'
      routePlugins:
        transformations:
          responseTransformation:
            transformation_template:
              body:
                text: 'extractor ({{ foo }}) header ({{ header("date")}}) json ({{ phone }})'
              extractors:
                foo:
                  header: 'date'
                  regex: '\w*, (.+):(.+):(.+) GMT'
                  subgroup: 2
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
  name: 'default'
  namespace: 'gloo-system'
spec:
  virtualHost:
    domains:
    - '*'
    routes:
    - matcher:
        prefix: '/petstore'
      routeAction:
        single:
          upstream:
            name: 'default-petstore-8080'
            namespace: 'gloo-system'
      routePlugins:
        faults:
          abort:
            percentage: 2.5
            httpStatus: 503
          delay:
            percentage: 5.3
            fixedDelay: '5s'
{{< /highlight >}}

### Prefix Rewrite {#prefixrewrite}

[PrefixRewrite]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins/transformation/prefix_rewrite.proto.sk#prefixrewrite" >}})
allows you to replace (rewrite) the matched request path with the specified value. Set to empty string (`""`) to remove
the matched request path.

### Timeout {#timeout}

The maximum [Duration](https://developers.google.com/protocol-buffers/docs/reference/csharp/class/google/protobuf/well-known-types/duration)
to try to handle the request, inclusive of error retries.

{{< highlight yaml "hl_lines=20" >}}
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: 'default'
  namespace: 'gloo-system'
spec:
  virtualHost:
    domains:
    - '*'
    routes:
    - matcher:
        prefix: '/petstore'
      routeAction:
        single:
          upstream:
            name: 'default-petstore-8080'
            namespace: 'gloo-system'
      routePlugins:
        timeout: '20s'
        retries:
          retryOn: 'connect-failure'
          numRetries: 3
          perTryTimeout: '5s'
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
  name: 'default'
  namespace: 'gloo-system'
spec:
  virtualHost:
    domains:
    - '*'
    routes:
    - matcher:
        prefix: '/petstore'
      routeAction:
        single:
          upstream:
            name: 'default-petstore-8080'
            namespace: 'gloo-system'
      routePlugins:
        retries:
          retryOn: 'connect-failure'
          numRetries: 3
          perTryTimeout: '5s'
{{< /highlight >}}

### Extensions {#extensions}