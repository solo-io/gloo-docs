---
title: Tracing Setup
weight: 4
description: Configure Gloo for tracing
---

# Tracing

Gloo makes it easy to implement tracing on your system through [Envoy's tracing capabilities](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/tracing.html).

#### Usage

*If you have not yet enabled tracing, please see the [configuration](#configuration) details below.*

- Produce a trace by passing the header: `x-client-trace-id`
  - This id provides a means of associating the spans produced during a trace. The value must be unique, a uuid4 is [recommended](https://www.envoyproxy.io/docs/envoy/v1.9.0/configuration/http_conn_man/headers#config-http-conn-man-headers-x-client-trace-id).
- Optionally annotate your trace with the `x-envoy-decorator-operation` header.
  - This will be emitted with the resulting trace and can be a means of identifying the origin of a given trace. Note that it will override any pre-specified route decorator. Additional details can be found [here](https://www.envoyproxy.io/docs/envoy/latest/configuration/http_filters/router_filter#config-http-filters-router-x-envoy-decorator-operation).

#### Configuration

- There are two steps to make tracing available through Gloo:
  1. Gloo specify a trace provider in the bootstrap config.
  1. Enable tracing on the listener.
  1. (Optional) Annotate routes with descriptors.

##### 1. Specify a tracing provider in the bootstrap config

The bootstrap config is the portion of Envoy's config that is applied when an Envoy process in intialized.
That means that you must either apply this configuration through Helm values during installation or that you must edit the proxy's config map and restart the pod.
We describe both methods below.

Several tracing providers are supported.
You can choose any that is supported by Envoy.
For a list of supported tracing providers and the configuration that they expect, please see Envoy's documentation on [trace provider configuration](https://www.envoyproxy.io/docs/envoy/v1.9.0/api-v2/config/trace/v2/trace.proto#config-trace-v2-tracing-http).
For demonstration purposes, we show how to specify the helm values for a *zipkin* trace provider below.

Note: some tracing providers, such as Zipkin, require a `collector_cluster` (the cluster which collects the traces) to be specified in the bootstrap config. If your provider requires a cluster to be specified, you can provide it in the config, as shown below. If your provider does not require a cluster you should omit that field. 

**Option 1: Set the trace provider through helm values:**

{{< highlight yaml "hl_lines=3-23" >}}
gatewayProxies:
  gatewayProxyV2:
    tracing:
      provider:
        name: envoy.zipkin
        typed_config:
          "@type": "type.googleapis.com/envoy.config.trace.v2.ZipkinConfig"
          collector_cluster: zipkin
          collector_endpoint: "/api/v1/spans"
      cluster:
        - name: zipkin
          connect_timeout: 1s
          type: strict_dns
          lb_policy: round_robin
          load_assignment:
            cluster_name: zipkin
            endpoints:
              - lb_endpoints:
                  - endpoint:
                      address:
                        socket_address:
                          address: zipkin
                          port_value: 1234
{{< /highlight >}}

When you install Gloo using these Helm values, Envoy will be configured with the tracing provider you specified.

**Option 2: Set the trace provider by editing the config map:**

First, edit the config map pertaining to your proxy. This should be `gateway-proxy-envoy-config` in the `gloo-system` namespace.

```bash
kubectl edit configmap -n gloo-system gateway-proxy-envoy-config
```
Apply the tracing provider changes. A sample Zipkin configuration is shown below.

{{< highlight yaml "hl_lines=4-10 33-45">}}
apiVersion: v1
kind: ConfigMap
data:
  envoy.yaml:
    tracing:
      http:
        name: envoy.zipkin
        typed_config:
          "@type": "type.googleapis.com/envoy.config.trace.v2.ZipkinConfig"
          collector_cluster: xds_cluster
          collector_endpoint: "/api/v1/spans"
    node:
      cluster: gateway
      id: "{{.PodName}}{{.PodNamespace}}"
      metadata:
        role: "{{.PodNamespace}}~gateway-proxy"
    static_resources:
      listeners: # collapsed for brevity
      clusters:
        - name: xds_cluster
          connect_timeout: 5.000s
          load_assignment:
            cluster_name: xds_cluster
            endpoints:
              - lb_endpoints:
                  - endpoint:
                      address:
                        socket_address:
                          address: gloo
                          port_value: 9977
          http2_protocol_options: {}
          type: STRICT_DNS
        - name: zipkin
          connect_timeout: 1s
          type: strict_dns
          lb_policy: round_robin
          load_assignment:
            cluster_name: zipkin
            endpoints:
              - lb_endpoints:
                  - endpoint:
                      address:
                        socket_address:
                          address: zipkin
                          port_value: 1234
{{< /highlight >}}


To apply the bootstrap config to Envoy we need to restart the process. An easy way to do this is with `kubectl delete pod`.

```bash
kubectl delete pod -n gloo-system gateway-proxy-[suffix]
```

When the `gateway-proxy` pod restarts it should have the new trace provider config.

##### 2. Enable tracing on the listener

After you have installed Gloo with a tracing provider, you can enable tracing on a listener-by-listener basis. Gloo exposes this feature through a listener plugin. Please see [the tracing listener plugin docs](../../gloo_routing/gateway_configuration/http_connection_manager/#tracing) for details on how to enable tracing on a listener.

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
