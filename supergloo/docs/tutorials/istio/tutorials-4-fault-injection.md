---
title: "Tutorial: Configuring Fault Injection"
menuTitle: Fault Injection
description: Tutorial on how to configure SuperGloo for Fault Injection.
weight: 4
---

# Overview

In this tutorial we'll take a look at how to inject faults within our mesh using SuperGloo.

Fault Injection refers to the ability to inject multiple forms of errors and/or delays into traffic for testing purposes.

Prerequisites for this tutorial:

- [SuperGloo Installed]({{% ref "/installation" %}})
- [Istio Installed]({{% ref "/mesh/install-istio" %}})
- [Bookinfo Sample Deployed]({{% ref "/tutorials/bookinfo" %}})
- [Routing Rules]({{% ref "/tutorials/istio/tutorials-1-trafficshifting" %}}) Note: it is not necessary to complete this tutorial, but rather to understand how routing rules work

# Concepts

## Fault Injection

By default, when traffic leaves pods destined for a service in the mesh, it is routed to one of the pods backing that service.
Using SuperGloo, we can inject faults directly into this traffic to test the resilience of the system as a whole. These faults can take the form of
delays and direct aborts of the requests.

# Tutorial

Now we'll demonstrate the fault injection routing rule using the Bookinfo app as our test subject.

First, ensure you've:

- [installed SuperGloo]({{% ref "/installation" %}})
- [installed Istio using SuperGloo]({{% ref "/mesh/install-istio" %}})
- [Deployed the Bookinfo sample app]({{% ref "/tutorials/bookinfo" %}})

Now let's open our view of the Product Page UI In our browser with the help of `kubectl port-forward`. Run the following command in another terminal window or the background:

```bash
kubectl --namespace default port-forward deployment/productpage-v1 9080
```

Open your browser to <http://localhost:9080/productpage>. When you refresh the page,
The reviews should always show up on the right side of the page. The color of the
stars will continuously shift, that is expected behavior.

Once that's done, we'll use the `supergloo` CLI to create a routing rule.
Let's run the command in *interactive mode* as it will help us better understand the structure of the routing rule.

Run the following command, providing the answers as specified:

```bash
supergloo apply routingrule faultinjection --interactive

? name for the Routing Rule:  rule1
? namespace for the Routing Rule:  supergloo-system
? create a source selector for this rule?  [y/N]:  (N) n
? create a destination selector for this rule?  [y/N]:  (N) y
? what kind of selector would you like to create?  Upstream Selector
? add an upstream (choose <done> to finish):  supergloo-system.default-reviews-9080
? add an upstream (choose <done> to finish):  <done>
? add a request matcher for this rule? [y/N]:  (N) n
? select a target mesh to which to apply this rule supergloo-system.istio
? select type of fault injection rule abort
? select type of abort rule http
? percentage of requests to inject (0-100) 50
? enter status code to abort request with (valid http status code) 404
```

There are currently two types of rules enabled: abort and delay. Abort rules are the category of rules which
intercept traffic and return specific responses. For example; the http abort rule changes the status code of the
response to the one specified by the rule. The other rule type, delay, adds timeout to requests which forces them
to take a specified amount of time before responding.

> Note that the reference to the upstream crd must be provided in the form of `NAMESPACE.NAME` where NAMESPACE refers to
> the namespace where the Upstream CRD has been written. Upstreams created by Discovery can be found in the namespace
> where SuperGloo is installed, which is `supergloo-system` by default.

The equivalent non-interactive command:

```bash
supergloo apply routingrule faultinjection abort http \
    --target-mesh supergloo-system.istio \
    -p 50 -s 404 --name rule1 \
    --dest-upstreams supergloo-system.default-reviews-9080
```

We can view the routing rule this created with `kubectl --namespace supergloo-system get routingrule reviews-v3 --output yaml`:

```yaml
apiVersion: supergloo.solo.io/v1
kind: RoutingRule
metadata:
  name: rule1
  namespace: supergloo-system
spec:
  destinationSelector:
    upstreamSelector:
      upstreams:
      - name: default-reviews-9080
        namespace: supergloo-system
  spec:
    faultInjection:
      abort:
        httpStatus: 404
      percentage: 50
  targetMesh:
    name: istio
    namespace: supergloo-system
status:
  reported_by: istio-config-reporter
  state: 1
```

> Note: RoutingRules can be managed entirely using YAML files and `kubectl`. The CLI provides commands for generating SuperGloo CRD YAML, understanding the state of the system, and debugging.

This rule tells SuperGloo to take all traffic bound for the upstream `default-reviews-9080` and change the response code of 50% of responses with
the http response code 404. In practice this means that ~50% of all traffic to that endpoint should fail.

> See [Understanding Upstreams & Discovery]({{% ref "/tutorials/istio/tutorials-1-trafficshifting#understanding-upstreams-discovery" %}}) for an explanation of how discovery creates upstreams for each subset of a service.

Now that our rule is created, we should be able to see the results. Open your browser back to <http://localhost:9080/productpage>
and refresh. Now, ~50% of the time the right half of the screen should display an error saying that there was an error
fetching the reviews. This means that the fault has been injected correctly

Let's update our rule to cause a delay instead.

```bash
supergloo apply routingrule faultinjection delay fixed \
    --target-mesh supergloo-system.istio \
    -p 50 -d 5s --name rule1 \
    --dest-upstreams supergloo-system.default-reviews-9080
```

Now, as before, the response will be impacted 50% of the time, but now the page will take ~5s longer to reload each time this rule is invoked.
