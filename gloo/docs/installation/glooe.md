---
title: Installing Gloo Enterprise
weight: 4
---

## Installing Gloo Enterprise

{{% notice note %}}
To install Gloo Enterprise you need a License Key. If you don't have one, go to **https://solo.io/glooe-trial** and
request a trial now.
{{% /notice %}}

Once you request a trial, an e-mail will be sent to you with your unique License Key.

If this is your first time running Gloo, you’ll need to download the command-line interface (CLI) onto your local
machine. You’ll use this CLI to interact with Gloo, including installing it onto your Kubernetes cluster.

<a name="cli_install"></a>

## Install Gloo via Command Line Interface (CLI)

### 1. Install CLI `glooctl`

Download the CLI Command appropriate to your environment:

* [MacOs]( {{% siteparam "glooctl-darwin" %}})
* [Linux]( {{% siteparam "glooctl-linux" %}})
* [Windows]( {{% siteparam "glooctl-windows" %}})

{{% notice note %}}
To facilitate usage we recommend renaming the file to **`glooctl`** and adding the CLI to your PATH.
{{% /notice %}}

If your are running Linux or MacOs, make sure the `glooctl` is an executable file by running:

```bash
chmod +x glooctl
```

Verify that you have the Enterprise version of the `glooctl` by running:

```bash
glooctl --version
```

You should have an output similar from the one below:

```bash
glooctl enterprise edition version 0.10.4
```

### 2. Choosing a deployment option for installing Gloo into your Kubernetes cluster

There are several options for deploying Gloo, depending on your use case and deployment platform. If this is your first
time installing Gloo Enterprise, we recommend starting with the **Gateway** Option.

* [*Gateway*](#gateway): Gloo's full feature set is available via its v1/Gateway API. The Gateway API is modeled on
Envoy's own API with the use of opinionated defaults to make complex configurations possible, while maintaining
simplicity when required.

* [*Ingress*](#ingress): Gloo will configure the Kubernetes Ingress resource, acting as a Kubernetes
Ingress Controller.  
*Note:* ingress objects must have the annotation `"kubernetes.io/ingress.class": "gloo"` to be processed by the Gloo
Ingress. **Ingress is not yet supported for Gloo enterprise. Refer to the [quick start guide](../quick_start) to see
how to install open source Gloo for Ingress.**

* [*Knative*](#knative): Gloo will integrate automatically with Knative as a cluster-level ingress for
[*Knative-Serving*](https://github.com/knative/serving). Gloo can be used in this way as a lightweight replacement
for Istio when using Knative-Serving.  **Knative is not yet supported for Gloo enterprise. Refer to the
[quick start guide](../quick_start) to see how to install open source Gloo for Knative.**

<a name="gateway"></a>
{{% notice note %}}
Your Unique License Key will be required for the next steps.
{{% /notice %}}

{{% notice info %}}
Each Key is valid for **31 days**. You can request a new key if your current key has expired.
The License Key is required only during the installation process. Once you install, a `secret` will be created to hold
your unique key.
{{% /notice %}}

#### 2a. Install the Gloo Gateway to your Kubernetes Cluster using `glooctl`

Once your Kubernetes cluster is up and running, run the following command to deploy the Gloo Gateway to the
`gloo-system` namespace:

```bash
glooctl install gateway --license-key YOUR_LICENSE_KEY
```

---
{{% notice note %}}
You can install Gloo to an existing namespace by providing the `-n` option. If the option is not provided,
the namespace defaults to `gloo-system`.
{{% /notice  %}}

```bash
glooctl install gateway -n my-namespace --license-key YOUR_LICENSE_KEY
```

---

Check that the Gloo pods and services have been created:

```bash
kubectl get all -n gloo-system
```

```noop
NAME                                                       READY   STATUS    RESTARTS   AGE
pod/api-server-7446cb9b87-gn4zq                            2/2     Running   0          11m
pod/discovery-759bd6cf85-m882f                             1/1     Running   0          11m
pod/extauth-f946d8bd6-6g5fk                                1/1     Running   0          11m
pod/gateway-568bfd477c-v58vb                               1/1     Running   0          11m
pod/gateway-proxy-5975479cd-vpkgf                          1/1     Running   0          11m
pod/gloo-5d6b989f7c-7qjts                                  1/1     Running   0          11m
pod/glooe-grafana-86445b465b-8ws99                         1/1     Running   0          11m
pod/glooe-prometheus-kube-state-metrics-8587f58df6-w7hjj   1/1     Running   0          11m
pod/glooe-prometheus-server-6bd6f4667d-d9bvl               2/2     Running   0          11m
pod/observability-5487584754-x5kjl                         1/1     Running   0          11m
pod/rate-limit-86b56f8c8b-l6nxw                            1/1     Running   1          11m
pod/redis-7f6954b84d-t4ss8                                 1/1     Running   0          11m

NAME                                          TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
service/apiserver-ui                          NodePort       10.106.251.89    <none>        8088:32328/TCP               11m
service/extauth                               ClusterIP      10.96.37.44      <none>        8080/TCP                     11m
service/gateway-proxy                         LoadBalancer   10.100.194.249   <pending>     80:30713/TCP,443:31424/TCP   11m
service/gloo                                  ClusterIP      10.96.200.9      <none>        9977/TCP                     11m
service/glooe-grafana                         ClusterIP      10.98.197.3      <none>        80/TCP                       11m
service/glooe-prometheus-kube-state-metrics   ClusterIP      None             <none>        80/TCP                       11m
service/glooe-prometheus-server               ClusterIP      10.107.113.171   <none>        80/TCP                       11m
service/rate-limit                            ClusterIP      10.101.67.230    <none>        18081/TCP                    11m
service/redis                                 ClusterIP      10.105.186.19    <none>        6379/TCP                     11m

NAME                                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/api-server                            1/1     1            1           11m
deployment.apps/discovery                             1/1     1            1           11m
deployment.apps/extauth                               1/1     1            1           11m
deployment.apps/gateway                               1/1     1            1           11m
deployment.apps/gateway-proxy                         1/1     1            1           11m
deployment.apps/gloo                                  1/1     1            1           11m
deployment.apps/glooe-grafana                         1/1     1            1           11m
deployment.apps/glooe-prometheus-kube-state-metrics   1/1     1            1           11m
deployment.apps/glooe-prometheus-server               1/1     1            1           11m
deployment.apps/observability                         1/1     1            1           11m
deployment.apps/rate-limit                            1/1     1            1           11m
deployment.apps/redis                                 1/1     1            1           11m

NAME                                                             DESIRED   CURRENT   READY   AGE
replicaset.apps/api-server-7446cb9b87                            1         1         1       11m
replicaset.apps/discovery-759bd6cf85                             1         1         1       11m
replicaset.apps/extauth-f946d8bd6                                1         1         1       11m
replicaset.apps/gateway-568bfd477c                               1         1         1       11m
replicaset.apps/gateway-proxy-5975479cd                          1         1         1       11m
replicaset.apps/gloo-5d6b989f7c                                  1         1         1       11m
replicaset.apps/glooe-grafana-86445b465b                         1         1         1       11m
replicaset.apps/glooe-prometheus-kube-state-metrics-8587f58df6   1         1         1       11m
replicaset.apps/glooe-prometheus-server-6bd6f4667d               1         1         1       11m
replicaset.apps/observability-5487584754                         1         1         1       11m
replicaset.apps/rate-limit-86b56f8c8b                            1         1         1       11m
replicaset.apps/redis-7f6954b84d                                 1         1         1       11m
```

## Next steps
See [Getting Started on Kubernetes](../../user_guides/basic_routing) to get started using the Gloo Gateway.

<a name="ingress"></a>

#### 2b. Install the Gloo Ingress Controller to your Kubernetes Cluster using `glooctl`

**Ingress is not yet supported for Gloo enterprise.** Refer to the [quick start guide](../quick_start) to see how to install 
open source Gloo for Ingress.

<a name="knative"></a>

#### 2c. Install the Gloo Knative Cluster Ingress to your Kubernetes Cluster using `glooctl`

**Knative is not yet supported for Gloo enterprise.** Refer to the [quick start guide](../quick_start) to see how to install 
open source Gloo for Knative.

## Next steps

Everything should be up and running. If you have questions about the installation or would like assistance, please
reach out to us on our [Slack](https://slack.solo.io/), on the channel [#gloo-enterprise](https://solo-io.slack.com/app_redirect?channel=gloo-enterprise).

## Uninstall

To uninstall Gloo and all related components, simply run the following.

```bash
glooctl uninstall
```

If you installed Gloo to a different namespace, you will have to specify that namespace using the `-n` option:

```bash
glooctl uninstall -n my-namespace
```

<!-- end -->
