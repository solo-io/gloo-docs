---
title: "Installing Linkerd"
weight: 1
---

## Overview

SuperGloo can be used to install, upgrade, and uninstall a supported mesh.

Currently supported meshes for installation:

- Istio
- Linkerd

## Installing Linkerd with SuperGloo

First, ensure that SuperGloo has been initialized in your kubernetes cluster via `supergloo init` or the
[Supergloo Helm Chart](https://github.com/solo-io/supergloo/tree/master/install/helm/supergloo). See the
[installation instructions]({{% ref "/installation" %}}) for detailed instructions on installing SuperGloo.

Once SuperGloo has been installed, we'll create an Install CRD with configuration parameters which will then
trigger SuperGloo to begin the mesh installation.

This can be done in one of two ways:

#### Option 1: Using the `supergloo` CLI:

```bash
supergloo install linkerd --name linkerd
```

See `supergloo install linkerd --help` for the full list of installation options for linkerd.


#### Option 2: Using `kubectl apply` on a yaml file:

```yaml
cat <<EOF | kubectl apply --filename -
apiVersion: supergloo.solo.io/v1
kind: Install
metadata:
  name: linkerd
spec:
  installationNamespace: linkerd
  mesh:
    linkerdMesh:
      enableAutoInject: true
      enableMtls: true
      linkerdVersion: stable-2.3.0
EOF
```

Once you've created the Install CRD, you can track the progress of the Linkerd installation:

```bash
kubectl --namespace linkerd get pod --watch
```

```noop
NAME                                      READY   STATUS    RESTARTS   AGE
linkerd-ca-585f97b595-l96mj               1/1     Running   0          46s
linkerd-controller-6954987c97-mjj8l       3/3     Running   0          45s
linkerd-grafana-7c6bbd8d-6vnqp            1/1     Running   0          46s
linkerd-prometheus-644f9f4754-5m2l8       1/1     Running   0          46s
linkerd-proxy-injector-8449944ffc-clh6j   1/1     Running   0          8s
linkerd-web-546b557f56-xsjqf              1/1     Running   0          5s
```

To tear everything down from this demo:

```bash
kubectl --namespace default delete --filename https://raw.githubusercontent.com/istio/istio/1.0.6/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl delete namespace not-injected
```

## Uninstalling Linkerd

If the `disabled` field is set to `true` on the install CRD. Doing so, again we have two options:

#### Option 1: Using the `supergloo` CLI:

```bash
supergloo uninstall --name linkerd
```

#### Option 2: Using `kubectl edit` and set `spec.disabled: true`:

```bash
kubectl edit install linkerd
```

{{< highlight yaml "hl_lines=11-12" >}}
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: supergloo.solo.io/v1
kind: Install
metadata:
  name: linkerd
  namespace: supergloo-system
spec:
   ## add the following line
   disabled: true
   ##
   installationNamespace: linkerd
   mesh:
     installedMesh:
       name: linkerd
       namespace: supergloo-system
     linkerdMesh:
       enableAutoInject: true
       enableMtls: true
       linkerdVersion: stable-2.3.0
{{< /highlight >}}

Verify un-installation has begun:

```bash
kubectl --namespace linkerd get pod --watch
```

```noop
NAME                                      READY   STATUS    RESTARTS   AGE
linkerd-ca-585f97b595-l96mj               1/1     Running   1          48m
linkerd-controller-6954987c97-mjj8l       3/3     Running   3          48m
linkerd-grafana-7c6bbd8d-6vnqp            1/1     Running   1          48m
linkerd-prometheus-644f9f4754-5m2l8       1/1     Running   1          48m
linkerd-proxy-injector-8449944ffc-clh6j   1/1     Running   1          47m
linkerd-web-546b557f56-xsjqf              1/1     Running   1          47m
linkerd-prometheus-644f9f4754-5m2l8       1/1     Terminating   1          48m
linkerd-proxy-injector-8449944ffc-clh6j   1/1     Terminating   1          47m
linkerd-ca-585f97b595-l96mj               1/1     Terminating   1          48m
linkerd-web-546b557f56-xsjqf              1/1     Terminating   1          47m
linkerd-ca-585f97b595-l96mj               0/1     Terminating   1          48m
linkerd-controller-6954987c97-mjj8l       3/3     Terminating   3          48m
linkerd-proxy-injector-8449944ffc-clh6j   0/1     Terminating   1          47m
linkerd-grafana-7c6bbd8d-6vnqp            1/1     Terminating   1          48m
linkerd-prometheus-644f9f4754-5m2l8       0/1     Terminating   1          48m
linkerd-prometheus-644f9f4754-5m2l8       0/1     Terminating   1          48m
linkerd-web-546b557f56-xsjqf              0/1     Terminating   1          47m
linkerd-proxy-injector-8449944ffc-clh6j   0/1     Terminating   1          47m
linkerd-proxy-injector-8449944ffc-clh6j   0/1     Terminating   1          47m
linkerd-proxy-injector-8449944ffc-clh6j   0/1     Terminating   1          47m
linkerd-prometheus-644f9f4754-5m2l8       0/1     Terminating   1          48m
linkerd-prometheus-644f9f4754-5m2l8       0/1     Terminating   1          48m
linkerd-grafana-7c6bbd8d-6vnqp            0/1     Terminating   1          48m
linkerd-ca-585f97b595-l96mj               0/1     Terminating   1          48m
linkerd-ca-585f97b595-l96mj               0/1     Terminating   1          48m
linkerd-controller-6954987c97-mjj8l       0/3     Terminating   3          48m
linkerd-controller-6954987c97-mjj8l       0/3     Terminating   3          48m
linkerd-controller-6954987c97-mjj8l       0/3     Terminating   3          48m
linkerd-web-546b557f56-xsjqf              0/1     Terminating   1          47m
linkerd-web-546b557f56-xsjqf              0/1     Terminating   1          47m
linkerd-grafana-7c6bbd8d-6vnqp            0/1     Terminating   1          48m
linkerd-grafana-7c6bbd8d-6vnqp            0/1     Terminating   1          48m
```

Note that the `linkerd` namespace will be left intact by this process, but can be safely removed using
`kubectl delete namespace linkerd`.
