---
title: Observability
weight: 3
description: How to monitor and trace within your Gloo setup.
---


Gloo can be configured to provide observability into your system. Depending on your needs, some aspects of observability must be configured during setup. Please see below for details.

- [Tracing Setup](#tracing)
- [Metrics Setup](#metrics)

# Tracing

Gloo makes it easy to implement tracing on your system through [Envoy's tracing capabilities.
](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/tracing.html)

#### Usage

*If you have not yet enabled tracing, please see the [configuration](#configuration) details below.*

- Produce a trace by passing the header: `x-client-trace-id`
  - This id provides a means of associating the spans produced during a trace. The value must be unique, a uuid4 is [recommended](https://www.envoyproxy.io/docs/envoy/v1.9.0/configuration/http_conn_man/headers#config-http-conn-man-headers-x-client-trace-id).
- Optionally annotate your trace with the `x-envoy-decorator-operation` header.
  - This will be emitted with the resulting trace and can be a means of identifying the origin of a given trace. Note that it will override any pre-specified route decorator. Additional details can be found [here](https://www.envoyproxy.io/docs/envoy/latest/configuration/http_filters/router_filter#config-http-filters-router-x-envoy-decorator-operation).

#### Configuration

- There are two steps to make tracing available through Gloo:
  1. Gloo specify a trace provider in the Helm values specification.
  1. Enable tracing on the listener.
  1. (Optional) Annotate routes with descriptors.

##### 1. Specify a tracing provider in Helm values

Several tracing providers are supported. You can choose any that is supported by Envoy and pass your specific configuration to Gloo during installation as a Helm value specification.

For a list of supported tracing providers and the configuration that they expect, please see Envoy's documentation on [trace provider configuration](https://www.envoyproxy.io/docs/envoy/v1.9.0/api-v2/config/trace/v2/trace.proto#config-trace-v2-tracing-http).
For demonstration purposes, we show how to specify the helm values for a *zipkin* trace provider below.

{{< highlight yaml "hl_lines=3-8" >}}
gatewayProxies:
  gatewayProxy:
    tracing: |
      name: envoy.zipkin
      typed_config:
        "@type": type.googleapis.com/envoy.config.trace.v2.ZipkinConfig
        collector_cluster: zipkin
        collector_endpoint: "/api/v1/spans"
{{< /highlight >}}


##### 2. Enable tracing on the listener

After you have installed Gloo with a tracing provider, you can enable tracing on a listener-by-listener basis. Gloo exposes this feature through a listener plugin. Please see [the tracing listener plugin docs](../../gateway/configuring_route_options/listener_plugins/#tracing) for details on how to enable tracing on a listener.

##### 3. (Optional) Annotate routes with descriptors

In order to associate a trace with a route, it can be helpful to annotate your routes with a descriptive name. This can be applied to the route, via a route plugin, or provided through a header `x-envoy-decorator-operation`.
If both means are used, the header's value will override the routes's value.

You can set a route descriptor with `kubectl edit virtualservice -n gloo-system [name-of-vs]`.
Edit your virtual service as shown below.

{{< highlight yaml "hl_lines=17-19" >}}
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata: # collapsed for brevity
spec:
  virtualHost:
    domains:
    - '*'
    name: gloo-system.default
    routes:
    - matcher:
        exact: /abc
      routeAction:
        single:
          upstream:
            name: my-upstream
            namespace: gloo-system
      routePlugins:
        tracing:
          routeDescriptor: my-route-from-abc-jan-01
        prefixRewrite:
          prefixRewrite: /
status: # collapsed for brevity
{{< /highlight >}}

# Metrics
All Gloo pods ship with optional [Prometheus](https://prometheus.io/) monitoring capabilities.

This functionality is turned off by default, and can be turned on a couple of different ways: through [Helm chart install
options](../../../../installation/gateway/kubernetes/#installing-on-kubernetes-with-helm); and through environment variables.

### Helm Chart Options

The first way is via the helm chart. All deployment objects in the helm templates accept an argument `stats` which
when set to true, start a stats server on the given pod.

For example, to add stats to the Gloo `gateway`, when installing with Helm add  `--set discovery.deployment.stats=true`.

```shell
helm install gloo/gloo \
  --name gloo \
  --namespace gloo-system \
  --set discovery.deployment.stats=true
```

Here's what the resulting `discovery` manifest would look like. Note the additions of the `prometheus.io` annotations,
and the `START_STATS_SERVER` environment variable.

{{< highlight yaml "hl_lines=18-21 32-33" >}}
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: gloo
    gloo: discovery
  name: discovery
  namespace: gloo-system
spec:
  replicas: 1
  selector:
    matchLabels:
      gloo: discovery
  template:
    metadata:
      labels:
        gloo: discovery
      annotations:
        prometheus.io/path: /metrics
        prometheus.io/port: "9091"
        prometheus.io/scrape: "true"
    spec:
      containers:
      - image: "quay.io/solo-io/discovery:0.11.1"
        imagePullPolicy: Always
        name: discovery
        env:
          - name: POD_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: START_STATS_SERVER
            value: "true"
{{< /highlight >}}

This flag will set the `START_STATS_SERVER` environment variable to true in the container which will start the stats
server on port `9091`.

### Environment Variables

The other method is to manually set the `START_STATS_SERVER=1` in the pod.

## Monitoring Gloo with Prometheus

Prometheus has great support for monitoring kubernetes pods. Docs for that can be found
[here](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config). If the stats
are enabled through the Helm chart than the Prometheus annotations are automatically added to the pod spec. And those
Prometheus stats are available from the admin page in our pods.

For example, assuming you installed Gloo as previously using Helm, and enabled stats for discovery, you
could then `kubectl port-forward <pod> 9091:9091` those pods (or deployments/services selecting those pods) to access
their admin page as follows.

```shell
kubectl --namespace gloo-system port-forward deployment/discovery 9091:9091
```

And then open <http://localhost:9091> for the admin page, including the Prometheus metrics at <http://localhost:9091/metrics>.
