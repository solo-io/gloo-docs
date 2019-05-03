---
title: "Deploying the Bookinfo Example"
menuTitle: Bookinfo Example
weight: 5
description: Istio Bookinfo example used by a number of the tutorials.
---

A number of tutorials make use of the [Istio Bookinfo](https://istio.io/docs/examples/bookinfo/) sample application.
This guide explains how to deploy the Bookinfo Application with automatic sidecar injection enabled.

**Prerequisites**: Istio or Linkerd must already be installed and running in your cluster. See [installing Istio](../../mesh/install-istio) or [installing Linkerd](../../mesh/install-linkerd) for instructions.

To deploy the bookinfo sample, first enable automatic sidecar injection on the default namespace (or any namespace of your choosing):

#### Istio Injection Label

```bash
kubectl label namespace default istio-injection=enabled
```

#### Linkerd Injection Annotation

```bash
kubectl annotate namespace default linkerd.io/inject=enabled
```

Next, create the bookinfo deployments and services:

```bash
kubectl apply --namespace default --filename \
    https://raw.githubusercontent.com/solo-io/supergloo/master/test/e2e/files/bookinfo.yaml
```

We should be up and running in a few minutes:

```bash
kubectl get pod --namespace default --watch
```

```noop
NAME                             READY     STATUS    RESTARTS   AGE
details-v1-6764bbc7f7-k4rhk      2/2       Running   0          27s
productpage-v1-54b8b9f55-sxxnw   2/2       Running   0          27s
ratings-v1-7bc85949-kh4f9        2/2       Running   0          27s
reviews-v1-fdbf674bb-z467l       2/2       Running   0          27s
reviews-v2-5bdc5877d6-gvgns      2/2       Running   0          27s
reviews-v3-dd846cc78-55wr5       2/2       Running   0          27s
```

We should see `2/2` containers are `READY`, since one of those containers is the sidecar injected by either Istio or Linkerd.
