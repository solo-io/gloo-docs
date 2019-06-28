---
title: "Tutorial: Configuring Security via Service-to-Service Communication"
menuTitle: Security
description: Tutorial on how to configure SuperGloo SecurityRules to restrict service-to-service communication.
weight: 5
---

# Overview

In this tutorial we'll take a look at how to restrict HTTP traffic within our mesh based on service identity.

Prerequisites for this tutorial:

- [SuperGloo Installed]({{% ref "/installation" %}})
- [Istio Installed]({{% ref "/mesh/install-istio" %}})
- [Bookinfo Sample Deployed]({{% ref "/tutorials/bookinfo" %}})

# Concepts

## Service-to-Service Communication

Whenever two injected Kubernetes pods communicate with each other, all traffic is routed through their sidecar proxies.
This enables SuperGloo to apply security policies which disable undesired communication channels. This is achieved through the
use of SuperGloo **SecurityRules**.

## SecurityRules

A SecurityRule is a [Kubernetes Custom Resource](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
that sets restrictions on HTTP traffic between pods in your meshes. Each SecurtiyRule provides [**selectors**]({{% ref "/v1/github.com/solo-io/supergloo/api/v1/selector.proto.sk" %}})
to indicate the source pods which are allowed to send HTTP requests and the destination pods to which they can be
sent.

> Note: If using SuperGloo with Istio, pods that share a service account will have the same set of permissions.
To enable fine-grained policies with Istio, ensure that all of your pods have individual
[service accounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/).

When no SecurityRules are present in your cluster, all traffic will be whitelisted between services. However, when one
or more SecurityRules are created, all communication that is not explicitly whitelisted within a SecurityRule will be met
with a `403 Forbidden` response from the sidecar.

> SuperGloo resources can be easily created using the CLI, but can also be created, updated, and deleted using
`.yaml` files and `kubectl`. It is our recommendation that you begin with the CLI in interactive mode to become familiar
with our APIs, but use version-controlled YAML files to persist and manage production configuration.

Let's take a look at an example SecurityRule:

```yaml
apiVersion: supergloo.solo.io/v1
kind: SecurityRule
metadata:
  name: productpage-to-reviews
  namespace: supergloo-system
spec:
  allowedMethods:
  - GET
  allowedPaths:
  - /details/*
  destinationSelector:
    upstreamSelector:
      upstreams:
      - name: default-reviews-9080
        namespace: supergloo-system
  sourceSelector:
    upstreamSelector:
      upstreams:
      - name: default-productpage-9080
        namespace: supergloo-system
  targetMesh:
    name: istio-istio-system
    namespace: supergloo-system

```

The above routing rule says to only permit those requests:

- Originating from any pods mapped to the service `productpage` in namespace `default` (port here is irrelevant)
- Destined to any pods backing the `reviews` service in the `default` namespace.
- With Method `GET`
- With Path prefixed by `/default/` (note that `*` can be used as a simple wildcard anywhere in the path string)

> Note: Upstreams will be automatically created in Supergloo's installation namespace by the `discovery` pod,
which is why the `namespace` on the [Upstream refs]({{% ref "/v1/github.com/solo-io/solo-kit/api/v1/ref.proto.sk" %}}) above says
`supergloo-system`. The namespace in which the service represents can be different than that where the Upstream lives.
For more information, see the [Kubernetes Upstream Spec](https://gloo.solo.io/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins/kubernetes/kubernetes.proto.sk/#upstreamspec).

Once a single SecurityRule is created, each one acts as a whitelist for traffic, causing all other traffic to be blacklisted.

# Tutorial

Now we'll demonstrate SecurityRules using the Bookinfo app.

First, ensure you've:

- [installed SuperGloo]({{% ref "/installation" %}})
- [installed Istio using SuperGloo]({{% ref "/mesh/install-istio" %}})
- [Deployed the Bookinfo sample app]({{% ref "/tutorials/bookinfo" %}})

Now let's open our view of the Product Page UI In our browser with the help of `kubectl port-forward`. Run the following command in another terminal window or the background:

```bash
kubectl --namespace default port-forward deployment/productpage-v1 9080
```

Open your browser to <http://localhost:9080/productpage>:

![Bookinfo Product Page](/img/bookinfo-default.png "Bookinfo Product Page")

You'll see the `Book Details` and `Book Reviews` subsections of our landing page are
working correctly. The `productpage` service which we are connected to queries
the `details`, `reviews`, and `ratings` services to populate the HTML elements you see
on the page.

We'll use some **SecurityRules** to show how we can restrict/enable the `productpage`
microservice communication with the other 3 services.

Let's start by creating a SecurityRule. This rule will automatically deny all unless it is
sent from the workloads/identities selected with the 'source' selector intended for those selected by the 'destination'
selector." Traffic flows will be only allowed if we explicitly whitelist it in one or more SecurityRules.

The application of SecurityRule logic by SuperGloo depends on the underlying mesh implementation. SuperGloo
uses Istio's [RBAC API](https://istio.io/docs/reference/config/authorization/istio.rbac.v1alpha1/) under
the hood to achieve traffic control.

Run the following command to create the SecurityRule in *interactive mode*:

```bash
# run supergloo cli in interactive mode
supergloo apply securityrule --interactive
? name for the Security Rule:  enable-security
? namespace for the Security Rule:  default
? create a source selector for this rule?  [y/N]:  y
? what kind of selector would you like to create?  Upstream Selector
? add an upstream (choose <done> to finish):  supergloo-system.default-productpage-9080
? add an upstream (choose <done> to finish):  <done>
? create a destination selector for this rule?  [y/N]:  Y
? what kind of selector would you like to create?  Upstream Selector
? add an upstream (choose <done> to finish):  supergloo-system.default-productpage-9080
? add an upstream (choose <done> to finish):  <done>
? select a target mesh to which to apply this rule supergloo-system.istio
? enter a comma-separated list of HTTP methods to allow for this rule, e.g.: GET,POST,PATCH (leave empty to allow all):
? enter a comma-separated list of HTTP paths to allow for this rule, e.g.: /api,/admin,/auth (leave empty to allow all):
```

- The equivalent non-interactive version of this command would be

```bash
supergloo apply securityrule \
    --name enable-security \
    --namespace default \
    --source-upstreams supergloo-system.default-productpage-9080 \
    --dest-upstreams supergloo-system.default-productpage-9080 \
    --target-mesh supergloo-system.istio-istio-system
```

- Or, using `kubectl`:

```yaml
cat <<EOF | kubectl apply --filename -
apiVersion: supergloo.solo.io/v1
kind: SecurityRule
metadata:
  name: enable-security
  namespace: default
spec:
  destinationSelector:
    upstreamSelector:
      upstreams:
      - name: default-productpage-9080
        namespace: supergloo-system
  sourceSelector:
    upstreamSelector:
      upstreams:
      - name: default-productpage-9080
        namespace: supergloo-system
  targetMesh:
    name: istio-istio-system
    namespace: supergloo-system
EOF
```

Now that we've created our first SecurityRule, Access-Control should be enforced in our cluster.
Now try refreshing the Product Page.

> Note: it may take up to a minute for configuration to propagate to all the Istio sidecars.

We should see that the details and reviews sections of the UI have turned into error messages:

![Bookinfo Product Page](/img/bookinfo-all-error.png "Bookinfo Product Page")

This confirms that the `productpage` service can no longer send requests to `details` or `reviews`.

Let's add a rule to permit the `productpage` to communicate with `details`.

- Using `supergloo` CLI:

```bash
supergloo apply securityrule \
    --name productpage-to-details \
    --namespace default \
    --source-upstreams supergloo-system.default-productpage-9080 \
    --dest-upstreams supergloo-system.default-details-9080 \
    --target-mesh supergloo-system.istio-istio-system
```

- Or with `kubectl`:

```yaml
cat <<EOF | kubectl apply --filename -
apiVersion: supergloo.solo.io/v1
kind: SecurityRule
metadata:
  name: productpage-to-details
  namespace: default
spec:
  destinationSelector:
    upstreamSelector:
      upstreams:
      - name: default-details-9080
        namespace: supergloo-system
  sourceSelector:
    upstreamSelector:
      upstreams:
      - name: default-productpage-9080
        namespace: supergloo-system
  targetMesh:
    name: istio-istio-system
    namespace: supergloo-system
EOF
```

Refresh the Product Page again. We should see a page like this:

![Bookinfo Product Page](/img/bookinfo-details-enabled.png "Bookinfo Product Page")

Communication has been enabled between `productpage` and `details`. Let's amend our rules to permit
`productpage` to reach any service in the `default` namespace:

- Using `supergloo` CLI:

```bash
supergloo apply securityrule \
    --name enable-security \
    --namespace default \
    --source-upstreams supergloo-system.default-productpage-9080 \
    --dest-namespaces default \
    --target-mesh supergloo-system.istio-istio-system
```

- Or with `kubectl`:

```yaml
cat <<EOF | kubectl apply --filename -
apiVersion: supergloo.solo.io/v1
kind: SecurityRule
metadata:
  name: enable-security
  namespace: default
spec:
  destinationSelector:
    namespaceSelector:
      namespaces:
      - default
  sourceSelector:
    upstreamSelector:
      upstreams:
      - name: default-productpage-9080
        namespace: supergloo-system
  targetMesh:
    name: istio-istio-system
    namespace: supergloo-system
EOF
```

Finally, refresh the Product Page a few more times. We should see everything working: the reviews, the details,
and the color-changing ratings stars under the reviews:

![Bookinfo Product Page](/img/bookinfo-all-enabled.png "Bookinfo Product Page")

> Note: Istio can take several minutes to update the caches on each sidecar proxy, which means that
it may take time for each of the SecurityRules to go into effect.

To re-enable all traffic without applying security policies, simply delete the security rules we created:

```bash
kubectl --namespace default delete securityrule --all
```

Try refreshing the page again. We should soon see that the `productpage` is able to communicate with the backend
services as before.
