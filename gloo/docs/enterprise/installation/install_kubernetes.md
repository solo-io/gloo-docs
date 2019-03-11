---
title: Installing on Kubernetes
weight: 2
description: Installing Gloo Enterprise into an existing Kubernetes cluster.
---

{{% notice note %}}
To install Gloo Enterprise you need a License Key. If you don't have one, go to **https://solo.io/glooe-trial** and
request a trial now. Once you request a trial, an e-mail will be sent to you with your unique License Key that you will
need as part of installing Gloo.
{{% /notice %}}

{{% notice info %}}
Each Key is valid for **31 days**. You can request a new key if your current key has expired.
The License Key is required only during the installation process. Once you install, a `secret` will be created to hold
your unique key.
{{% /notice %}}

If this is your first time running Gloo, you’ll need to download the command-line interface (CLI) called `glooctl` onto
your local machine. You’ll use this CLI to interact with Gloo, including installing it onto your Kubernetes cluster.
Directions on installing `glooctl` are [here](../install_glooctl).

Before starting installation, please ensure that you've prepared your Kubernetes cluster per the community [Prep Kubernetes](../../../installation/kubernetes/setup_kubernetes)
instructions.

## Overall flow for installing

1. [Prepare Kubernetes Cluster](../../../installation/kubernetes/setup_kubernetes)
1. [Install Gloo Enterprise using CLI](#install_cli)
1. [Verify installation](#verify)

If for some reason you ever needed to uninstall Gloo, please follow [these instructions](#uninstall)

There are several options for deploying Gloo, depending on your use case and deployment platform.

* **Gateway**: (**recommended**) Gloo's full feature set is available via its v1/Gateway API. The Gateway API
is modeled on Envoy's own API with the use of opinionated defaults to make complex configurations possible,
while maintaining simplicity when required.

* **Ingress**: Gloo will support configuration the Kubernetes Ingress resource, acting as a Kubernetes
Ingress Controller. (**Not currently supported**)

{{% notice note %}}
ingress objects must have the annotation `"kubernetes.io/ingress.class": "gloo"` to be processed by the Gloo Ingress.
{{% /notice %}}

* **Knative**: Gloo will integrate automatically with Knative as a cluster-level ingress for
[*Knative-Serving*](https://github.com/knative/serving). Gloo can be used in this way as a lightweight replacement
for Istio when using Knative-Serving. (**Not currently supported**)

{{% notice info %}}
If this process does not work, please [open an issue](https://github.com/solo-io/gloo/issues/new).
We are happy to answer questions on our [diligently staffed Slack channel](https://slack.solo.io/) as well.
{{% /notice %}}

---

## Install Gloo via Command Line Interface (CLI) {#install_cli}

Choosing a deployment option for installing Gloo into your Kubernetes cluster:

* [Gateway](#gateway) (**recommended**)
* [Ingress](#ingress)
* [Knative](#knative)

{{% notice note %}}
Gloo Enterprise installation require you to use an extra `--license-key YOUR_LICENSE_KEY` with your license key you
received either as part of your subscription or as part of a trial request from **<https://solo.io/glooe-trial>**
{{% /notice %}}

{{% notice info %}}
You can install Gloo to an existing namespace by providing the `-n` option, e.g. `glooctl install gateway -n my-namespace`.
If the option is not provided, the namespace defaults to `gloo-system`.
{{% /notice %}}

### Install the Gloo Gateway {#gateway}

Once your Kubernetes cluster is up and running, run the following command to deploy the Gloo Gateway to the `gloo-system` namespace:

```shell
glooctl install gateway --license-key YOUR_LICENSE_KEY
```

After you [verify your installation](#verify), please see [Getting Started on Kubernetes](../../../user_guides/basic_routing)
to get started using the Gloo Gateway.

### Install the Gloo Ingress Controller {#ingress}

Once your Kubernetes cluster is up and running, run the following command to deploy the Gloo Ingress to the `gloo-system` namespace:

```shell
glooctl install ingress --license-key YOUR_LICENSE_KEY
```

After you [verify your installation](#verify), please see [Getting Started with Kubernetes Ingress](../../../user_guides/basic_ingress)
to get started using the Gloo Ingress Controller.

### Install the Gloo Knative Cluster Ingress {#knative}

Once your Kubernetes cluster is up and running, run the following command to deploy Knative-Serving components to the
`knative-serving` namespace and Gloo to the `gloo-system` namespace:

```shell
glooctl install knative --license-key YOUR_LICENSE_KEY
```

After you [verify your installation](#verify), please see [Getting Started with Gloo and Knative](../../../user_guides/gloo_with_knative)
to use Gloo as your Knative Ingress.

---

## Verify your Installation {#verify}

Check that the Gloo pods and services have been created. Depending on your install option, you may see some differences
from the following example. And if you choose to install Gloo into a different namespace than the default `gloo-system`,
then you will need to query your chosen namespace instead.

```shell
kubectl get all -n gloo-system
```

```noop
NAME                                READY     STATUS    RESTARTS   AGE
pod/discovery-f7548d984-slddk       1/1       Running   0          5m
pod/gateway-5689fd59d7-wsg7f        1/1       Running   0          5m
pod/gateway-proxy-9d79d48cd-wg8b8   1/1       Running   0          5m
pod/gloo-5b7b748dbf-jdsvg           1/1       Running   0          5m

NAME                    TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
service/gateway-proxy   LoadBalancer   10.97.232.107   <pending>     8080:31800/TCP   5m
service/gloo            ClusterIP      10.100.64.166   <none>        9977/TCP         5m

NAME                            DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/discovery       1         1         1            1           5m
deployment.apps/gateway         1         1         1            1           5m
deployment.apps/gateway-proxy   1         1         1            1           5m
deployment.apps/gloo            1         1         1            1           5m

NAME                                      DESIRED   CURRENT   READY     AGE
replicaset.apps/discovery-f7548d984       1         1         1         5m
replicaset.apps/gateway-5689fd59d7        1         1         1         5m
replicaset.apps/gateway-proxy-9d79d48cd   1         1         1         5m
replicaset.apps/gloo-5b7b748dbf           1         1         1         5m
```

The Knative install option will also install Knative Serving components into the `knative-service` namespace.

```shell
kubectl get all -n knative-serving
```

```noop
NAME                              READY     STATUS    RESTARTS   AGE
pod/activator-5c8d977d45-6x9s4    1/1       Running   0          2m
pod/autoscaler-5cd4bb6dbc-kwt4q   1/1       Running   0          2m
pod/controller-66cd7d99df-c9fnx   1/1       Running   0          30s
pod/webhook-6d9568d-q27vv         1/1       Running   0          2m

NAME                        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
service/activator-service   ClusterIP   10.104.212.24   <none>        80/TCP,9090/TCP     2m
service/autoscaler          ClusterIP   10.98.232.40    <none>        8080/TCP,9090/TCP   2m
service/controller          ClusterIP   10.102.58.151   <none>        9090/TCP            2m
service/webhook             ClusterIP   10.106.233.95   <none>        443/TCP             2m

NAME                         DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/activator    1         1         1            1           2m
deployment.apps/autoscaler   1         1         1            1           2m
deployment.apps/controller   1         1         1            1           2m
deployment.apps/webhook      1         1         1            1           2m

NAME                                    DESIRED   CURRENT   READY     AGE
replicaset.apps/activator-5c8d977d45    1         1         1         2m
replicaset.apps/autoscaler-5cd4bb6dbc   1         1         1         2m
replicaset.apps/controller-66cd7d99df   1         1         1         2m
replicaset.apps/webhook-6d9568d         1         1         1         2m

NAME                                                 AGE
image.caching.internal.knative.dev/fluentd-sidecar   2m
image.caching.internal.knative.dev/queue-proxy       2m
```

---

## Uninstall {#uninstall}

To uninstall Gloo and all related components, simply run the following.

{{% notice note %}}
This will also remove Knative-Serving, if it was installed by `glooctl`.
{{% /notice %}}

```shell
glooctl uninstall
```

If you installed Gloo to a different namespace, you will have to specify that namespace using the `-n` option:

```shell
glooctl uninstall -n my-namespace
```

## Next Steps

After you've installed Gloo, please check out our [Basic Routing Guide with Gloo Enterprise Console](../../basic_routing_console)
and our [User Guides](../../../user_guides).