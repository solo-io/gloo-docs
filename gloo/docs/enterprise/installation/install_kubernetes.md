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

Before starting installation, please ensure that you've prepared your Kubernetes cluster per the community
[Prep Kubernetes]({{< ref "/installation/kubernetes/setup_kubernetes" >}}) instructions.

## Overall flow for installing

1. [Prepare Kubernetes Cluster]({{< ref "/installation/kubernetes/setup_kubernetes" >}})
1. [Install using CLI](#install_cli)
1. [Install using Helm](#install_helm)
1. [Verify installation](#verify)

If for some reason you ever needed to uninstall Gloo, please follow [these instructions](#uninstall)

There are several options for deploying Gloo, depending on your use case and deployment platform.

* **Gateway**: Gloo's full feature set is available via its v1/Gateway API. The Gateway API
is modeled on Envoy's own API with the use of opinionated defaults to make complex configurations possible,
while maintaining simplicity when required.

* **Ingress** (**Not currently supported**): Gloo will support configuration the Kubernetes Ingress resource, acting as a Kubernetes
Ingress Controller.

{{% notice note %}}
ingress objects must have the annotation `"kubernetes.io/ingress.class": "gloo"` to be processed by the Gloo Ingress.
{{% /notice %}}

* **Knative** (**Not currently supported**): Gloo will integrate automatically with Knative as a cluster-level ingress for
[*Knative-Serving*](https://github.com/knative/serving). Gloo can be used in this way as a lightweight replacement
for Istio when using Knative-Serving.

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
You can install Gloo to an existing namespace by providing the `--namespace` option, e.g. `glooctl install gateway --namespace my-namespace`.
If the option is not provided, the namespace defaults to `gloo-system`.
{{% /notice %}}

### Install the Gloo Gateway {#gateway}

Once your Kubernetes cluster is up and running, run the following command to deploy the Gloo Gateway to the `gloo-system` namespace:

```shell
glooctl install gateway --license-key YOUR_LICENSE_KEY
```

After you [verify your installation](#verify), please see [Getting Started on Kubernetes]({{< ref "/user_guides/basic_routing" >}})
to get started using the Gloo Gateway.

### Install the Gloo Ingress Controller {#ingress}

Once your Kubernetes cluster is up and running, run the following command to deploy the Gloo Ingress to the `gloo-system` namespace:

```shell
glooctl install ingress --license-key YOUR_LICENSE_KEY
```

After you [verify your installation](#verify), please see [Getting Started with Kubernetes Ingress]({{< ref "/user_guides/basic_ingress" >}})
to get started using the Gloo Ingress Controller.

### Install the Gloo Knative Cluster Ingress {#knative}

Once your Kubernetes cluster is up and running, run the following command to deploy Knative-Serving components to the
`knative-serving` namespace and Gloo to the `gloo-system` namespace:

```shell
glooctl install knative --license-key YOUR_LICENSE_KEY
```

After you [verify your installation](#verify), please see [Getting Started with Gloo and Knative]({{< ref "/user_guides/gloo_with_knative" >}})
to use Gloo as your Knative Ingress.

---

## Install Gloo with Helm {#install_helm}

This is the recommended method for installing Gloo to your production environment as it offers rich customization to
the Gloo control plane and the proxies Gloo manages.

### Accessing the Gloo chart repository

As a first step, you have to add the Gloo repository to the list of known chart repositories:

```shell
helm repo add glooe http://storage.googleapis.com/gloo-ee-helm
```

You can then list all the charts in the repository by running the following command:

```shell
helm search glooe/gloo-ee --versions
```

```noop
NAME         	CHART VERSION	APP VERSION	DESCRIPTION
glooe/gloo-ee	0.13.13      	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.13.12      	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.13.11      	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.13.10      	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.13.9       	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.13.8       	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.13.6       	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.13.5       	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.13.4       	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.13.2       	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.13.1       	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.13.0       	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.12.3       	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.12.2       	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.12.1       	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.12.0       	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.11.3       	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.11.2       	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.11.1       	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.11.0       	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.10.19      	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.10.18      	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.10.17      	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.10.16      	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.10.15      	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.10.13      	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.10.12      	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.10.11      	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.10.10      	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.10.9       	           	A Helm chart for Kubernetes
glooe/gloo-ee	0.10.8       	           	A Helm chart for Kubernetes
...
```

The Gloo Enterprise Helm chart only supports `gateway` deployment.

```shell
helm install glooe/gloo-ee --name glooe --namespace gloo-system \
  --set-string license_key=YOUR_LICENSE_KEY
```

Helm will install the `gateway` deployment of Gloo to the cluster your _KUBECONFIG_ is pointing to. Remember to specify
the two additional options, otherwise Helm will install Gloo to the `default` namespace and generate a funny release
`name` for it.

After you've installed Gloo, please check out our [User Guides]({{< ref "/user_guides" >}}).

### Customizing your installation

You can customize the Gloo installation by providing your own value file.

For example, you can create a file named `value-overrides.yaml` with the following content:

```yaml
rbac:
  create: false
settings:
  writeNamespace: my-custom-namespace
```

and use it to override default values in the Gloo Helm chart:

```shell
helm install glooe/gloo-ee --name glooe --namespace gloo-system \
  --filename value-overrides.yaml \
  --set-string license_key=YOUR_LICENSE_KEY
```

The right-most file specified takes precedence (see the [Helm docs](https://helm.sh/docs/helm/#helm-install) for more
info on the `install` command).

#### List of Gloo chart values

The table below describes all the values that you can override in your custom values file.

| option                                                    | type     | description                                                                                                                                                                                |
| --------------------------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| namespace.create                                          | bool     | create the installation namespace                                                                                                                                                          |
| rbac.create                                               | bool     | create rbac rules for the gloo-system service account                                                                                                                                      |
| crds.create                                               | bool     | create CRDs for Gloo (turn off if installing with Helm to a cluster that already has Gloo CRDs)                                                                                            |
| settings.watchNamespaces                                  | []string | whitelist of namespaces for gloo to watch for services and CRDs. leave empty to use all namespaces                                                                                         |
| settings.writeNamespace                                   | string   | namespace where intermediary CRDs will be written to, e.g. Upstreams written by Gloo Discovery.                                                                                            |
| settings.create                                           | bool     | create a Settings CRD which configures Gloo controllers at boot time                                                                                                                       |
| gloo.deployment.image.repository                          | string   | image name (registry/repository) for the gloo container. this container is the core controller of the system which watches CRDs and serves Envoy configuration over xDS                    |
| gloo.deployment.image.tag                                 | string   | tag for the gloo container                                                                                                                                                                 |
| gloo.deployment.image.pullPolicy                          | string   | image pull policy for gloo container                                                                                                                                                       |
| gloo.deployment.xdsPort                                   | string   | port where gloo serves xDS API to Envoy                                                                                                                                                    |
| gloo.deployment.replicas                                  | int      | number of gloo xds server instances to deploy                                                                                                                                              |
| gloo.deployment.stats                                     | bool     | expose pod level stats                                                                                                                                                                     |
| discovery.deployment.image.repository                     | string   | image name (registry/repository) for the discovery container. this container adds service discovery and function discovery to Gloo                                                         |
| discovery.deployment.image.tag                            | string   | tag for the discovery container                                                                                                                                                            |
| discovery.deployment.image.pullPolicy                     | string   | image pull policy for discovery container                                                                                                                                                  |
| discovery.deployment.stats                                | bool     | expose pod level stats                                                                                                                                                                     |
| gateway.enabled                                           | bool     | enable Gloo API Gateway features                                                                                                                                                           |
| gateway.deployment.image.repository                       | string   | image name (registry/repository) for the gateway controller container. this container translates Gloo's VirtualService CRDs to the intermediary representation used by the gloo controller |
| gateway.deployment.image.tag                              | string   | tag for the gateway controller container                                                                                                                                                   |
| gateway.deployment.image.pullPolicy                       | string   | image pull policy for the gateway controller container                                                                                                                                     |
| gateway.deployment.stats                                  | bool     | expose pod level stats                                                                                                                                                                     |
| gatewayProxies[].gatewayProxy.deployment.image.repository | string   | image name (registry/repository) for the gateway proxy container. this proxy receives configuration created via VirtualService CRDs                                                        |
| gatewayProxies[].gatewayProxy.deployment.image.tag        | string   | tag for the gateway proxy container                                                                                                                                                        |
| gatewayProxies[].gatewayProxy.deployment.image.pullPolicy | string   | image pull policy for the gateway proxy container                                                                                                                                          |
| gatewayProxies[].gatewayProxy.deployment.httpPort         | string   | HTTP port for the proxy                                                                                                                                                                    |
| gatewayProxies[].gatewayProxy.deployment.replicas         | int      | number of gateway proxy instances to deploy                                                                                                                                                |
| gatewayProxies[].gatewayProxy.service.type                | string   | gateway [service type](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types). default is `LoadBalancer`                                      |
| gatewayProxies[].gatewayProxy.service.clusterIP           | string   | static clusterIP (or `None`) when `gatewayProxies[].gatewayProxy.service.type` is `ClusterIP`                                                                                              |
| gatewayProxies[].gatewayProxy.service.httpPort            | string   | HTTP port for the gateway service                                                                                                                                                          |
| gatewayProxies[].gatewayProxy.service.httpsPort           | string   | HTTPS port for the gateway service                                                                                                                                                         |
| gatewayProxies[].gatewayProxy.service.extraAnnotations    | map      | annotations for the gateway service                                                                                                                                                        |
| ingress.deployment.image.pullPolicy                       | string   | image pull policy for the ingress controller container                                                                                                                                     |
| ingressProxy.deployment.image.tag                         | string   | tag for the ingress proxy container                                                                                                                                                        |
| ingressProxy.deployment.image.repository                  | string   | image name (registry/repository) for the ingress proxy container. this proxy receives configuration created via Kubernetes Ingress objects                                                 |
| ingressProxy.deployment.image.pullPolicy                  | string   | image pull policy for the ingress proxy container                                                                                                                                          |
| ingressProxy.deployment.httpPort                          | string   | HTTP port for the proxy                                                                                                                                                                    |
| ingressProxy.deployment.httpsPort                         | string   | HTTPS port for the proxy                                                                                                                                                                   |
| ingressProxy.deployment.replicas                          | int      | number of ingress proxy instances to deploy                                                                                                                                                |

---

## Verify your Installation {#verify}

Check that the Gloo pods and services have been created. Depending on your install option, you may see some differences
from the following example. And if you choose to install Gloo into a different namespace than the default `gloo-system`,
then you will need to query your chosen namespace instead.

```shell
kubectl --namespace gloo-system get all
```

```noop
NAME                                                       READY   STATUS    RESTARTS   AGE
pod/api-server-56fcb78878-d9mxt                            2/2     Running   0          5m21s
pod/discovery-759bd6cf85-sphjb                             1/1     Running   0          5m22s
pod/extauth-679d587db8-l9k56                               1/1     Running   0          5m21s
pod/gateway-568bfd477c-487zw                               1/1     Running   0          5m22s
pod/gateway-proxy-c84cbd647-n9kz2                          1/1     Running   0          5m22s
pod/gloo-6979c5bd8-2dfrj                                   1/1     Running   0          5m22s
pod/glooe-grafana-86445b465b-mnn8t                         1/1     Running   0          5m22s
pod/glooe-prometheus-kube-state-metrics-8587f58df6-954pw   1/1     Running   0          5m22s
pod/glooe-prometheus-server-6bd6f4667d-zqffp               2/2     Running   0          5m21s
pod/observability-6db6c659dd-v4bkp                         1/1     Running   0          5m21s
pod/rate-limit-6b847b95c8-kwcbd                            1/1     Running   1          5m21s
pod/redis-7f6954b84d-ff4ck                                 1/1     Running   0          5m21s

NAME                                          TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
service/apiserver-ui                          NodePort       10.107.135.104   <none>        8088:31160/TCP               5m22s
service/extauth                               ClusterIP      10.109.93.97     <none>        8080/TCP                     5m22s
service/gateway-proxy                         LoadBalancer   10.106.26.131    <pending>     80:31627/TCP,443:30931/TCP   5m22s
service/gloo                                  ClusterIP      10.103.56.88     <none>        9977/TCP                     5m22s
service/glooe-grafana                         ClusterIP      10.103.252.250   <none>        80/TCP                       5m22s
service/glooe-prometheus-kube-state-metrics   ClusterIP      None             <none>        80/TCP                       5m22s
service/glooe-prometheus-server               ClusterIP      10.100.244.136   <none>        80/TCP                       5m22s
service/rate-limit                            ClusterIP      10.100.54.112    <none>        18081/TCP                    5m22s
service/redis                                 ClusterIP      10.97.72.199     <none>        6379/TCP                     5m22s

NAME                                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/api-server                            1/1     1            1           5m21s
deployment.apps/discovery                             1/1     1            1           5m22s
deployment.apps/extauth                               1/1     1            1           5m21s
deployment.apps/gateway                               1/1     1            1           5m22s
deployment.apps/gateway-proxy                         1/1     1            1           5m22s
deployment.apps/gloo                                  1/1     1            1           5m22s
deployment.apps/glooe-grafana                         1/1     1            1           5m22s
deployment.apps/glooe-prometheus-kube-state-metrics   1/1     1            1           5m22s
deployment.apps/glooe-prometheus-server               1/1     1            1           5m22s
deployment.apps/observability                         1/1     1            1           5m21s
deployment.apps/rate-limit                            1/1     1            1           5m21s
deployment.apps/redis                                 1/1     1            1           5m21s

NAME                                                             DESIRED   CURRENT   READY   AGE
replicaset.apps/api-server-56fcb78878                            1         1         1       5m21s
replicaset.apps/discovery-759bd6cf85                             1         1         1       5m22s
replicaset.apps/extauth-679d587db8                               1         1         1       5m21s
replicaset.apps/gateway-568bfd477c                               1         1         1       5m22s
replicaset.apps/gateway-proxy-c84cbd647                          1         1         1       5m22s
replicaset.apps/gloo-6979c5bd8                                   1         1         1       5m22s
replicaset.apps/glooe-grafana-86445b465b                         1         1         1       5m22s
replicaset.apps/glooe-prometheus-kube-state-metrics-8587f58df6   1         1         1       5m22s
replicaset.apps/glooe-prometheus-server-6bd6f4667d               1         1         1       5m21s
replicaset.apps/observability-6db6c659dd                         1         1         1       5m21s
replicaset.apps/rate-limit-6b847b95c8                            1         1         1       5m21s
replicaset.apps/redis-7f6954b84d                                 1         1         1       5m21s
```

The Knative install option will also install Knative Serving components into the `knative-service` namespace.

```shell
kubectl --namespace knative-serving get all
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

If you installed Gloo to a different namespace, you will have to specify that namespace using the `--namespace` option:

```shell
glooctl uninstall --namespace my-namespace
```

## Next Steps

After you've installed Gloo, please check out our [Basic Routing Guide with Gloo Enterprise Console]({{< ref "/enterprise/basic_routing_console" >}})
and our [User Guides]({{< ref "/user_guides" >}}).
