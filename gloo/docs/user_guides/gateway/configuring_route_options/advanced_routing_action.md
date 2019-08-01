---
title: Advanced Route Actions
weight: 37
description: Advanced routing action rules for Gloo.
---

Gloo uses a [`VirtualService`]({{% ref "/v1/github.com/solo-io/gloo/projects/gateway/api/v1/virtual_service.proto.sk" %}})
Custom Resource (CRD) to allow users to specify one or more [Route]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#route" %}})
rules to handle as a group. This guide will discuss how matched routes act upon requests. Please refer to the
[Advanced Route Matching]({{% ref "/user_guides/gateway/configuring_route_options/advanced_routing" %}}) guide for more information on how to pattern match
requests in routes. These are examples of how to use the [Route Action]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#routeaction" %}}).

To give you some context, Gloo [Virtual Services]({{% ref "/v1/github.com/solo-io/gloo/projects/gateway/api/v1/virtual_service.proto.sk#VirtualService" %}}) contain zero or more [Route]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#route" %}}) objects.
Each [Route]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#route" %}}) includes a
[Matcher]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#matcher" %}}) and a [Route Action]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#routeaction" %}}). 
The matcher provides conditional rules to select which requests should be handled by a given route, and the action defines 
how to handle or act upon a given request. This guide will primarily focus on the details
of configuring a [Route Action]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#routeaction" %}}).

You can use the glooctl command line to provide you a template manifest that you can start editing. The `--dry-run` option
tells glooctl to NOT actually create the custom resource and instead output the custom resource manifest. This is a
great way to get an initial manifest template that you can edit and then `kubectl apply` later. For example, the
[`glooctl add route`]({{% ref "/cli/glooctl_add_route" %}}) command will generate a `VirtualService` resource if it
does not already exist, and it will add a route spec like the following which shows forwarding all requests to `/petstore`
to the upstream `default-petstore-8080` in the `gloo-system` namespace.

```shell
glooctl add route --dry-run \
  --name default \
  --path-prefix /petstore \
  --dest-name default-petstore-8080 \
  --dest-namespace gloo-system
```

{{< highlight yaml "hl_lines=14-18" >}}
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
status: {}
{{< /highlight >}}

A route action contains one and only one of the following three options:

* [`single`](#single): forward request to a [single destination]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#destination" %}})
* [`multi`](#multi): forward request to a group of one or more destination ([MultiDestination]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#multidestination" %}})) based on a percentage weight associated with each destination
* [`upstream_group`](#upstream_group): similar to a MultiDestination that can be shared across multiple routes and virtual services

### Single Destination {#single}

A [Destination]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#destination" %}}) can be of one of three types:

* [`upstream`](#dest-upstream)
* [`kube`](#dest-kube)
* [`consul`](#dest-consul)

#### Upstream destination {#dest-upstream}

This destination type routes matching requests to a given upstream. The required `upstream` [ResourceRef]({{% ref "/v1/github.com/solo-io/solo-kit/api/v1/ref.proto.sk#resourceref" %}}) 
field defines the name and namespace of the upstream to which the request should be routed. 
Additionally, two optional fields can be specified: `destinationSpec` [DestinationSpec]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins.proto.sk#destinationspec" %}})
and `subset` [Subset]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/subset.proto.sk#subset" %}}).
The `destinationSpec` is an optional plugin definition based on the upstream, e.g. forwarding a request to an AWS Lambda function may require
additional information on how to transform the request. The `subset` is a way to define a selector such that the request
will be routed to a defined subset of all the request handlers (e.g. pods) in an upstream. Let's look at some examples.

To forward all requests that match a route matcher, you can provide the upstream definition like in the following
manifest snippet from the previous example.

{{< highlight yaml "hl_lines=5-8" >}}
routes:
- matcher:
    prefix: /petstore
  routeAction:
    single:
      upstream:
        name: default-petstore-8080
        namespace: gloo-system
{{< /highlight >}}

To forward all requests to a REST function within an upstream, you would provide an additional rest `desinationSpec` like
as follows.

{{< highlight yaml "hl_lines=6-11" >}}
routes:
- matcher:
    prefix: /petstore/findPetById
  routeAction:
    single:
      destinationSpec:
        rest:
          functionName: findPetById
          parameters:
            headers:
              :path: /petstore/findPetById/{id}
      upstream:
        name: default-petstore-8080
        namespace: gloo-system
{{< /highlight >}}

This previous would be like execution the following glooctl command:

```shell
glooctl add route \
  --name default \
  --path-prefix /petstore/findPetById \
  --dest-name default-petstore-8080 \
  --dest-namespace gloo-system \
  --rest-function-name findPetById \
  --rest-parameters ':path=/petstore/findPetById/{id}'
```

##### Subset

[Subset]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/subset.proto.sk#subset" %}}) currently lets you
provide a Kubernetes selector to allow request forwarding to a subset of Kubernetes Pods within the upstream associated
Kubernetes Service. There are currently two steps required to get subsetting to work for Kubernetes upstreams, which are
the only upstream type currently supported. 

**First**, you need to edit the [Spec]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins/kubernetes/kubernetes.proto.sk" %}})
of the Kubernetes Upstream that you want to define subsets for by adding a [`subsetSpec`]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins/subset_spec.proto.sk#subsetspec" %}}). 
The `subsetSpec` contains a list of `selectors`, each of which consist of a set of `keys`. Each key represents a Kubernetes 
label key. These selectors determine how the subsets for the upstream are to be calculated. For example, the following 
`subsetSpec`:

```yaml
subsetSpec:
  selectors:
  - keys:
    - color
    - size
  - keys:
    - size
```

means that the pods for the upstream will be divided into subsets based both on the values of the `color` and `size` 
labels, and on the value of the `size` label alone. Envoy requires this information to limit the combinations of subsets 
that it needs to compute. The [Envoy documentation](https://github.com/envoyproxy/envoy/blob/master/source/docs/subset_load_balancer.md) 
contains a great explanation of how on subset load balancing works and we strongly recommend that you read it if you plan to use this feature.

**Second**, you need to add a [`subset`]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/subset.proto.sk#subset" %}})
within the [`Destination` spec]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#destination" %}})
of the Route Action. This will determine which of the upstream subsets should be selected as destination for this route.

Following is an example of using a label, e.g. `color: blue`, to subset pods handling requests.

These are the Upstream changes that allow you to use the label `color` as a subset selector:

{{< highlight yaml "hl_lines=15-18" >}}
apiVersion: gloo.solo.io/v1
  kind: Upstream
    labels:
      discovered_by: kubernetesplugin
      service: petstore
    name: default-petstore-8080
    namespace: gloo-system
  spec:
    upstreamSpec:
      kube:
        selector:
          app: petstore
        serviceName: petstore
        serviceNamespace: default
        subsetSpec:
          selectors:
          - keys:
            - color
        servicePort: 8080
        serviceSpec:
          rest:
...
{{< /highlight >}}

And then you need to configure the subset within the Virtual Service route action, e.g. the following will only forward
requests to a subset of the Petstore Service pods that have a label, `color: blue`.

{{< highlight yaml "hl_lines=22-24" >}}
apiVersion: gateway.solo.io/v1
  kind: VirtualService
  metadata:
    name: default
    namespace: gloo-system
  spec:
    virtualHost:
      domains:
      - '*'
      name: gloo-system.default
      routes:
      - matcher:
          prefix: /petstore/findPetById
        routeAction:
          single:
            destinationSpec:
              rest:
                functionName: findPetById
                parameters:
                  headers:
                    :path: /petstore/findPetById/{id}
            subset:
              values:
                color: blue
            upstream:
              name: default-petstore-8080
              namespace: gloo-system
{{< /highlight >}}

{{% notice note %}}
If no pods match the selector, i.e. empty set, then the route action will fall back to forwarding the request to all
pods served by that upstream.
{{% /notice %}}

#### Kubernetes destination {#dest-kube}

If you are running Gloo in a Kubernetes cluster, it is possible to directly specify 
[Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/) as routing destinations. 
The `kube` destination type has two required fields:

* `ref` is a [ResourceRef]({{% ref "/v1/github.com/solo-io/solo-kit/api/v1/ref.proto.sk#resourceref" %}}) to the service that should receive traffic
* `port` is an `int` which represents the port on which the service is listening. This must be one of the ports defined in the Kubernetes service spec

The following configuration will forward all requests to `/petstore` to port `8080` on the Kubernetes service named 
`petstore` in the `default` namespace.

{{< highlight yaml "hl_lines=6-10" >}}
routes:
- matcher:
    prefix: /petstore
  routeAction:
    single:
      kube:
        ref:
          name: petstore
          namespace: default
        port: 8080
{{< /highlight >}}

#### Consul destination {#dest-consul}

Gloo is capable of discovering services registered with [HashiCorp Consul](https://www.hashicorp.com/products/consul/). 
If this feature has been enabled via the `serviceDiscovery` field in the [ConsulConfiguration]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/settings.proto.sk#consulconfiguration" %}}) 
section of the `Settings` resource, it is possible to specify Consul services as routing destinations.

A single Consul service usually maps to several service instances, which can have distinct sets of tags, listen on 
different ports, and live in multiple data centers. To give a concrete example, here is a simplified response you might 
get when querying Consul for a service with a given name:

```json
[
  {
    "ServiceID": "32a2a47f7992:nodea:5000",
    "ServiceName": "my-db",
    "Address": "192.168.1.1",
    "Datacenter": "dc1",
    "ServicePort": 5000,
    "ServiceTags": [
      "primary"
    ]
  },
  {
    "ServiceID": "42a2a47f7992:nodeb:5001",
    "ServiceName": "my-db",
    "Address": "192.168.1.2",
    "Datacenter": "dc1",
    "ServicePort": 5001,
    "ServiceTags": [
      "secondary"
    ]
  },
  {
    "ServiceID": "52a2a47f7992:nodec:6000",
    "ServiceName": "my-db",
    "Address": "192.168.2.1",
    "Datacenter": "dc2",
    "ServicePort": 6000,
    "ServiceTags": [
      "secondary"
    ]
  }
]
```

The [`consul` destination type]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#consulservicedestination" %}}) 
allows you to target a subset of these service instances via the optional `tags` and `dataCenters` fields. Gloo will 
detect the correspondent IP addresses and ports and load balance traffic between them.

{{% notice note %}}
When providing the `tags` option, Gloo will only match service instances that **exactly** match the given tag set.
{{% /notice %}}

For example, the following configuration will forward all matching requests to the second and third service instances,

{{< highlight yaml "hl_lines=6-9" >}}
routes:
- matcher:
    prefix: /db
  routeAction:
    single:
      consul:
        serviceName: my-db
        tags:
        - secondary
{{< /highlight >}}

while this next example will forward the same requests only to the first two instances (the ones in data center `dc1`)

{{< highlight yaml "hl_lines=6-9" >}}
routes:
- matcher:
    prefix: /db
  routeAction:
    single:
      consul:
        serviceName: my-db
        dataCenters:
        - dc1
{{< /highlight >}}

Finally, not specifying any optional filter fields will cause requests to be forwarded to all three service instances:

{{< highlight yaml "hl_lines=6-9" >}}
routes:
- matcher:
    prefix: /db
  routeAction:
    single:
      consul:
        serviceName: my-db
{{< /highlight >}}

{{% notice note %}}
As is the case with [`Subsets`](#subset), Gloo will fall back to forwarding the request to all available service 
instances if the given criteria do not match any subset of instances.
{{% /notice %}}

### Multiple Destinations {#multi}

The [MultiDestination]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#multidestination" %}})
has an array of one or more [WeightedDestination]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#weighteddestination" %}})
specs that are a single [Destination]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#destination" %}}) 
plus a `weight`. The weight is the percentage of request traffic forwarded to that
destination where the percentage is: `weight` divided by sum of all weights in `MultiDestination`.

Here's an example to help make this more concrete. Assuming we've got two versions of a service - `default-myservice-v1-8080`
and `default-myservice-v2-8080` - and we want to route 10% of request traffic to `default-myservice-v2-8080` as part of a
Canary deploy, i.e., route a small portion of traffic to a new version to make sure new version works in the service before
decommissioning the original version. Here's what a route would look like with 90% of traffic going to v1 and 10% to v2.

{{< highlight yaml "hl_lines=5-16" >}}
routes:
- matcher:
    prefix: /myservice
  routeAction:
    multi:
      destinations:
      - weight: 9
        destination:
          upstream:
            name: default-myservice-v1-8080
            namespace: gloo-system
      - weight: 1
        destination:
          upstream:
            name: default-myservice-v2-8080
            namespace: gloo-system
{{< /highlight >}}

{{% notice note %}}
You can use a destination of any type as part of a multi destination action. This means that the same route can split 
traffic between `upstream`, `kube`, and `consul` destinations.
{{% /notice %}}

### Upstream Group {#upstream_group}

An [UpstreamGroup]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/proxy.proto.sk#upstreamgroup" %}}) addresses
an issue of how do you have multiple routes or virtual services referencing the same multiple weighted destinations where
you want to change the weighting consistently for all calling routes. This is a common need for Canary deployments
where you want all calling routes to forward traffic consistently across the two service versions.

For example, if I'm doing a Canary deployment of a new shopping cart service, I may want my inventory and ordering services
to call the same weighted destinations consistently, AND I want the ability to update the destination weights, e.g. go
from 90% v3 and 10% v4 => 50% v3 and 50% v4 **without** needing to know what routes are referencing my upstream destinations.

![Upstream Group example](/img/inv2.png)

There are two steps to using an upstream group. First, you need to create an Upstream Group custom resource, and then you
need to reference that Upstream Group from your one or more route actions. Let's build on our [Multiple Destination](#multi)
example.

#### Create Upstream Group

{{< highlight yaml >}}
apiVersion: gloo.solo.io/v1
kind: UpstreamGroup
metadata:
  name: my-service-group
  namespace: gloo-system
spec:
  destinations:
  - destination:
      upstream:
        name: default-myservice-v1-8080
        namespace: gloo-system
    weight: 9
  - destination:
      upstream:
        name: default-myservice-v2-8080
        namespace: gloo-system
    weight: 1
{{< /highlight >}}

#### Reference Upstream Group in your Route Actions

{{< highlight yaml "hl_lines=5-8 12-15" >}}
routes:
- matcher:
    prefix: /myservice
  routeAction:
    upstreamGroup:
      name: my-service-group
      namespace: gloo-system
- matcher:
    prefix: /some/other/path
  routeAction:
    upstreamGroup:
      name: my-service-group
      namespace: gloo-system
{{< /highlight >}}

Once deployed, you can update the weights in your shared Upstream Group and those changes will be picked up by all routes
that referencing that upstream group instance.
