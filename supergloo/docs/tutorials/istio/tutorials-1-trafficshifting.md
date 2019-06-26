---
title: "Tutorial: Configuring Traffic Shifting"
menuTitle: Traffic Shifting
description: Tutorial on how to configure SuperGloo for Traffic Shifting.
weight: 1
---

# Overview

In this tutorial we'll take a look at how to shift traffic within our mesh using SuperGloo.

Traffic shifting refers to the ability to divert traffic from its original destination to an alternate destination or
set of destinations, with load balancing across destinations.

Prerequisites for this tutorial:

- [SuperGloo Installed]({{% ref "/installation" %}})
- [Istio Installed]({{% ref "/mesh/install-istio" %}})
- [Bookinfo Sample Deployed]({{% ref "/tutorials/bookinfo" %}})

# Concepts

## Traffic Shifting

By default, when traffic leaves pods destined for a service in the mesh, it is routed to one of the pods backing that service.
Using SuperGloo, we can change how these requests are routed, for example by choosing a subset of destination pods to which all
traffic should be directed, or splitting traffic by percentage across a number of subsets. Traffic can even be
shifted to other services regardless of their hostname. This can be useful, for example, if you want to route traffic to a default backend.

## RoutingRules

Traffic Shifting is achieved in SuperGloo via the use of **RoutingRules**. A RoutingRule is a
[Kubernetes Custom Resource](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
which applies some routing configuration to the underlying mesh(es) which SuperGloo is managing.

SuperGloo resources can be easily created using the CLI, but can also be created, updated, and deleted using
`.yaml` files and `kubectl`. It is our recommendation that you begin with the CLI in interactive mode to become familiar
with our APIs, but use version-controlled YAML files to persist and manage production configuration.

RoutingRules can be used to apply HTTP features to all traffic within a mesh, or a subset of that traffic. RoutingRules allow
the following parameters for restricting the types of traffic the feature will apply to:

- Sources: only apply this rule to requests originating from these client pods.
- Destinations: only apply this rule to requests sent to these destination pods.
- Request Matchers: only apply this rule to requests matching these HTTP paths/methods/headers.

For a clearer understanding of how a routing rule works, take a look at the following diagram:

![Routing Rule Architecture](/img/supergloo-arch-1-routingrule.png "Routing Rule Architecture")

Routing rule on the right tells SuperGloo to inject faults on 50% of any `POST` requests sent from `site` to `apiserver` on `/users`.

The rule on the left instructs SuperGloo to retry all failed requests in the mesh up to 3 times, regardless of origin, destination, or the content of request.

# Tutorial

Now we'll demonstrate the traffic shifting routing rule using the Bookinfo app as our test subject.

First, ensure you've:

- [installed SuperGloo]({{% ref "/installation" %}})
- [installed Istio using supergloo]({{% ref "/mesh/install-istio" %}})
- [Deployed the Bookinfo sample app]({{% ref "/tutorials/bookinfo" %}})

Now let's open our view of the Product Page UI In our browser with the help of `kubectl port-forward`. Run the following
command in another terminal window or the background:

```shell
kubectl port-forward -n default deployment/productpage-v1 9080
```

Open your browser to <http://localhost:9080/productpage>. When you refresh the page,
you should see that the representation of stars below the Book Reviews alternates between
being black, red, and not showing at all. This is because, by default, traffic is
being shifted between `v1/v2/v3` of the `reviews` service.

Once that's done, we'll use the `supergloo` CLI to create a routing rule.
Let's run the command in *interactive mode* as it will help us better understand the structure of the routing rule.

Run the following command, providing the  answers as specified:

```shell
supergloo apply routingrule trafficshifting --interactive

? name for the Routing Rule:  reviews-v3
? namespace for the Routing Rule:  supergloo-system
? create a source selector for this rule?  [y/N]:  (N) n
? create a destination selector for this rule?  [y/N]:  (N) y
? what kind of selector would you like to create?  Upstream Selector
? add an upstream (choose <done> to finish):  supergloo-system.default-reviews-9080
? add an upstream (choose <done> to finish):  <done>
? add a request matcher for this rule? [y/N]:  (N) n
? select a target mesh to which to apply this rule supergloo-system.istio
select the upstreams to which you wish to direct traffic
? add an upstream (choose <done> to finish):  supergloo-system.default-reviews-v3-9080
? add an upstream (choose <done> to finish):  <done>
? choose a weight for {default-reviews-v3-9080 supergloo-system} 1
```

The weight we selected for our destination is a *relative weight*. Weights are relative
across the set of destinations chosen for traffic shifting. If only one is
selected, any non-zero weight will equate to 100% of traffic.

> Note that the reference to the upstream crd must be provided in the form of `NAMESPACE.NAME` where NAMESPACE refers
> to the namespace where the Upstream CRD has been written. Upstreams created by Discovery can be found in the namespace
> where SuperGloo is installed, which is `supergloo-system` by default.

The equivalent non-interactive command:

```shell
supergloo apply routingrule trafficshifting \
    --name reviews-v3 \
    --dest-upstreams supergloo-system.default-reviews-9080 \
    --target-mesh supergloo-system.istio-istio-system \
    --destination supergloo-system.default-reviews-v3-9080:1
```

We can view the routing rule this created with `kubectl get routingrule --namespace supergloo-system reviews-v3 --output yaml`:

```yaml
apiVersion: supergloo.solo.io/v1
kind: RoutingRule
metadata:
  name: reviews-v3
  namespace: supergloo-system
  resourceVersion: "22111"
spec:
  destinationSelector:
    upstreamSelector:
      upstreams:
      - name: default-reviews-9080
        namespace: supergloo-system
  spec:
    trafficShifting:
      destinations:
        destinations:
        - destination:
            upstream:
              name: default-reviews-v3-9080
              namespace: supergloo-system
          weight: 1
  targetMesh:
    name: istio-istio-system
    namespace: supergloo-system
status:
  reported_by: istio-config-reporter
  state: 1
```

> Note: RoutingRules can be managed entirely using YAML files and `kubectl`. The CLI provides commands for generating SuperGloo CRD YAML, understanding the state of the system, and debugging.

This rule tells SuperGloo to take all traffic bound for the upstream `default-reviews-9080` and route 100% of it to `default-reviews-v3-9080`. The `default-reviews-9080` upstream represents the whole set of pods for the `default.reviews` service, while `default-reviews-v3-9080` represents the subset of those pods with the label `app: v3`.

> See [Understanding Upstreams & Discovery](#understanding-upstreams-discovery) for an explanation of how discovery creates upstreams for each subset of a service.

Now that our rule is created, we should be able to see the results. Open your browser back to <http://localhost:9080/productpage> and refresh. Now you'll see that red stars appear every time.

Lets update our rule to split traffic between the `v2` and `v3` versions of reviews:

```shell
supergloo apply routingrule trafficshifting \
    --name reviews-v3 \
    --dest-upstreams supergloo-system.default-reviews-9080 \
    --target-mesh supergloo-system.istio-istio-system \
    --destination supergloo-system.default-reviews-v2-9080:1 \
    --destination supergloo-system.default-reviews-v3-9080:1
```

The `:1` for each destination represents the relative weight, i.e. traffic will be split
1-1 or 50%-50% between `v2` and `v3`. Try refreshing your browser page again.

## Understanding Upstreams & Discovery

The difference between the `reviews` and `reviews-v3` upstreams can be seen using `kubectl` with `jq`:

```shell
# all pods with app: reviews
kubectl get upstream -n supergloo-system default-reviews-9080 -o json | jq .spec.upstreamSpec
```

```json
{
  "kube": {
    "selector": {
      "app": "reviews"
    },
    "serviceName": "reviews",
    "serviceNamespace": "default",
    "servicePort": 9080
  }
}
```

```shell
# all pods with app: reviews && version: v3
kubectl get upstream -n supergloo-system default-reviews-v3-9080 -o json | jq .spec.upstreamSpec
```

```json
{
  "kube": {
    "selector": {
      "app": "reviews",
      "version": "v3"
    },
    "serviceName": "reviews",
    "serviceNamespace": "default",
    "servicePort": 9080
  }
}
```

This is because the Discovery service installed along with SuperGloo has created Upstreams for each unique permutation of labels for a given service:

```shell
kubectl get upstream -n supergloo-system

NAME                                                    AGE
default-details-9080                                    10m
default-details-v1-9080                                 10m
default-kubernetes-443                                  10m
default-productpage-9080                                10m
default-productpage-v1-9080                             10m
default-ratings-9080                                    10m
default-ratings-v1-9080                                 10m
default-reviews-9080                                    10m
default-reviews-v1-9080                                 10m
default-reviews-v2-9080                                 10m
default-reviews-v3-9080                                 10m
istio-system-grafana-3000                               10m
istio-system-istio-citadel-8060                         10m
istio-system-istio-citadel-9093                         10m
istio-system-istio-galley-443                           10m
istio-system-istio-galley-9093                          10m
istio-system-istio-pilot-15010                          10m
istio-system-istio-pilot-15011                          10m
istio-system-istio-pilot-8080                           10m
istio-system-istio-pilot-9093                           10m
istio-system-istio-pilot-pilot-15010                    10m
istio-system-istio-pilot-pilot-15011                    10m
istio-system-istio-pilot-pilot-8080                     10m
istio-system-istio-pilot-pilot-9093                     10m
istio-system-istio-policy-15004                         10m
istio-system-istio-policy-9091                          10m
istio-system-istio-policy-9093                          10m
istio-system-istio-policy-policy-15004                  10m
istio-system-istio-policy-policy-9091                   10m
istio-system-istio-policy-policy-9093                   10m
istio-system-istio-sidecar-injector-443                 10m
istio-system-istio-telemetry-15004                      10m
istio-system-istio-telemetry-42422                      10m
istio-system-istio-telemetry-9091                       10m
istio-system-istio-telemetry-9093                       10m
istio-system-istio-telemetry-telemetry-15004            10m
istio-system-istio-telemetry-telemetry-42422            10m
istio-system-istio-telemetry-telemetry-9091             10m
istio-system-istio-telemetry-telemetry-9093             10m
istio-system-jaeger-agent-5775                          10m
istio-system-jaeger-agent-6831                          10m
istio-system-jaeger-agent-6832                          10m
istio-system-jaeger-collector-14267                     10m
istio-system-jaeger-collector-14268                     10m
istio-system-jaeger-query-16686                         10m
istio-system-prometheus-9090                            10m
istio-system-tracing-80                                 10m
istio-system-zipkin-9411                                10m
kube-system-kube-dns-53                                 10m
kube-system-kubernetes-dashboard-80                     10m
kube-system-kubernetes-dashboard-reconcile-v1-10-1-80   10m
```

Discovery creates upstreams from Kubernetes Services in the following way:

- for each kubernetes service
  - for each port on the service
  - for each unique subset of labels found on pods backing that service
    create an upstream named **`<service-namespace>-<service-name>-<label-values>-<service-port>`**

This makes selection of a destination in SuperGloo simply a matter of selecting the correct upstream. Upstreams can also be created manually via YAML files + `kubectl apply`.
