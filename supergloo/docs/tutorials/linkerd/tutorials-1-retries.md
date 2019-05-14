---
title: "Tutorial: Configuring Retries"
menuTitle: Retries
description: Tutorial on how to configure Linkerd for Retries.
weight: 1
---

# Overview

In this tutorial we'll take a look at how to use SuperGloo and Linkerd to retry failed requests
within our mesh.

Prerequisites for this tutorial:

- [SuperGloo Installed]({{% ref "/installation" %}})
- [Linkerd Installed]({{% ref "/mesh/install-linkerd" %}})

# Concepts

## Retries

Having a service mesh installed to your cluster allows you to automatically retry failed requests.

By placing the task of retrying failed requests on the service mesh, your applications will no
longer need to implement their own retry logic.

This tutorial will show you how to set a retry policy to handle intermittent failures
using Linkerd as the base mesh.

## RoutingRules

Automatic Retries are achieved in SuperGloo with the use of *RoutingRules*.

For an in-depth overview of RoutingRules, see the [Istio Traffic Shifting Tutorial]({{% ref "/tutorials/istio/tutorials-1-trafficshifting" %}})

# Tutorial

Now we'll demonstrate the RetryPolicy RoutingRule using a service with intermittent failures.

First, ensure you've:

- [installed SuperGloo]({{% ref "/installation" %}})
- [installed Linkerd using SuperGloo]({{% ref "/mesh/install-linkerd" %}})

Now we'll deploy 2 pods to our cluster:

- a service that fails HTTP requests intermittently.
- a pod running `sleep` that we can `kubectl exec` into and run commands.

First, to ensure they'll get injected with the Linkerd sidecar:

```bash
kubectl --namespace default annotate linkerd.io/inject=enabled
```

> Feel free to replace namespace `default` with one of your choosing.

Now, deploy the services:

```bash
kubectl --namespace default apply --filename \
    https://raw.githubusercontent.com/solo-io/supergloo/master/test/e2e/files/test-service.yaml
kubectl --namespace default apply --filename \
    https://raw.githubusercontent.com/solo-io/supergloo/master/test/e2e/files/testrunner.yaml
```

We should see the pods get created with the sidecar:

```bash
kubectl --namespace default get pod
```

```noop
NAME                               READY   STATUS    RESTARTS   AGE
test-service-v1-664b69bb58-4kmhs   2/2     Running   0          43s
testrunner-77776ccd75-bqltg        2/2     Running   0          1m
```

We know the pods have had their sidecar injected if their ready count is `2/2`.

Let's open a terminal and exec into the `testrunner` pod:

```bash
TESTRUNNER=$(kubectl --namespace default get pod -l app=testrunner -ojsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
kubectl exec -ti -n default ${TESTRUNNER} -c testrunner -- bash
```

This should open a root shell inside the container:

```bash
root@testrunner-77776ccd75-bqltg:/go#
```

Let's try a few `curl` requests against our `test-service`:

```bash
curl -v test-service.default.svc.cluster.local:8080
curl -v test-service.default.svc.cluster.local:8080
curl -v test-service.default.svc.cluster.local:8080
```

The response will alternate between a `500 Internal Server Error` and `200 OK`:

```bash
root@testrunner-77776ccd75-k598f:/go# curl -v test-service.default.svc.cluster.local:8080
* Rebuilt URL to: test-service.default.svc.cluster.local:8080/
*   Trying 10.104.27.25...
* TCP_NODELAY set
* Connected to test-service.default.svc.cluster.local (10.104.27.25) port 8080 (#0)
> GET / HTTP/1.1
> Host: test-service.default.svc.cluster.local:8080
> User-Agent: curl/7.52.1
> Accept: */*
>
< HTTP/1.1 200 OK
< date: Fri, 19 Apr 2019 17:59:35 GMT
< content-length: 0
<
* Curl_http_done: called premature == 0
* Connection #0 to host test-service.default.svc.cluster.local left intact

root@testrunner-77776ccd75-k598f:/go# curl -v test-service.default.svc.cluster.local:8080
* Rebuilt URL to: test-service.default.svc.cluster.local:8080/
*   Trying 10.104.27.25...
* TCP_NODELAY set
* Connected to test-service.default.svc.cluster.local (10.104.27.25) port 8080 (#0)
> GET / HTTP/1.1
> Host: test-service.default.svc.cluster.local:8080
> User-Agent: curl/7.52.1
> Accept: */*
>
< HTTP/1.1 500 Internal Server Error
< date: Fri, 19 Apr 2019 17:59:36 GMT
< content-length: 0
<
* Curl_http_done: called premature == 0
* Connection #0 to host test-service.default.svc.cluster.local left intact

root@testrunner-77776ccd75-k598f:/go# curl -v test-service.default.svc.cluster.local:8080
* Rebuilt URL to: test-service.default.svc.cluster.local:8080/
*   Trying 10.104.27.25...
* TCP_NODELAY set
* Connected to test-service.default.svc.cluster.local (10.104.27.25) port 8080 (#0)
> GET / HTTP/1.1
> Host: test-service.default.svc.cluster.local:8080
> User-Agent: curl/7.52.1
> Accept: */*
>
< HTTP/1.1 200 OK
< date: Fri, 19 Apr 2019 17:59:37 GMT
< content-length: 0
<
* Curl_http_done: called premature == 0
* Connection #0 to host test-service.default.svc.cluster.local left intact
```

Seems like a pretty unreliable service. Let's see if we can add some resiliency with a
Retry **RoutingRule**!

Run the following command to create a simple RoutingRule with the retry config we want:

```bash
supergloo apply routingrule retries budget \
    --name retries \
    --target-mesh supergloo-system.linkerd \
    --min-retries 3 \
    --ratio 0.1 \
    --ttl 1m
```

Or the equivalent using `kubectl`:

```yaml
cat <<EOF | kubectl apply --filename -
apiVersion: supergloo.solo.io/v1
kind: RoutingRule
metadata:
  name: retries
  namespace: supergloo-system
spec:
  spec:
    retries:
      retryBudget:
        minRetriesPerSecond: 3
        retryRatio: 0.1
        ttl: 60s
  targetMesh:
    name: linkerd
    namespace: supergloo-system
EOF
```

The `retryBudget` is a special Linkerd implementation of retries using a
[retry budget policy](https://blog.linkerd.io/2019/02/22/how-we-designed-retries-in-linkerd-2-2/).
For other SuperGloo meshes, you should use the `maxRetries` config option. Both options can
be shared by the same rule to allow configuring multiple meshes via the same rule. See
[the RoutingRule API Reference](../../../v1/github.com/solo-io/supergloo/api/v1/routing.proto.sk)
for more information.

We should see results almost immediately. Let's go back to our `testrunner` shell and
retry those `curl` commands.

```bash
curl -v test-service.default.svc.cluster.local:8080
curl -v test-service.default.svc.cluster.local:8080
curl -v test-service.default.svc.cluster.local:8080
```

Should show 3 back-to-back `200 OK`:

```bash
root@testrunner-77776ccd75-k598f:/go# curl -v test-service.default.svc.cluster.local:8080
* Rebuilt URL to: test-service.default.svc.cluster.local:8080/
*   Trying 10.104.27.25...
* TCP_NODELAY set
* Connected to test-service.default.svc.cluster.local (10.104.27.25) port 8080 (#0)
> GET / HTTP/1.1
> Host: test-service.default.svc.cluster.local:8080
> User-Agent: curl/7.52.1
> Accept: */*
>
< HTTP/1.1 200 OK
< date: Fri, 19 Apr 2019 18:29:36 GMT
< content-length: 0
<
* Curl_http_done: called premature == 0
* Connection #0 to host test-service.default.svc.cluster.local left intact

root@testrunner-77776ccd75-k598f:/go# curl -v test-service.default.svc.cluster.local:8080
* Rebuilt URL to: test-service.default.svc.cluster.local:8080/
*   Trying 10.104.27.25...
* TCP_NODELAY set
* Connected to test-service.default.svc.cluster.local (10.104.27.25) port 8080 (#0)
> GET / HTTP/1.1
> Host: test-service.default.svc.cluster.local:8080
> User-Agent: curl/7.52.1
> Accept: */*
>
< HTTP/1.1 200 OK
< date: Fri, 19 Apr 2019 18:29:37 GMT
< content-length: 0
<
* Curl_http_done: called premature == 0
* Connection #0 to host test-service.default.svc.cluster.local left intact

root@testrunner-77776ccd75-k598f:/go# curl -v test-service.default.svc.cluster.local:8080
* Rebuilt URL to: test-service.default.svc.cluster.local:8080/
*   Trying 10.104.27.25...
* TCP_NODELAY set
* Connected to test-service.default.svc.cluster.local (10.104.27.25) port 8080 (#0)
> GET / HTTP/1.1
> Host: test-service.default.svc.cluster.local:8080
> User-Agent: curl/7.52.1
> Accept: */*
>
< HTTP/1.1 200 OK
< date: Fri, 19 Apr 2019 18:29:38 GMT
< content-length: 0
<
* Curl_http_done: called premature == 0
* Connection #0 to host test-service.default.svc.cluster.local left intact
```
