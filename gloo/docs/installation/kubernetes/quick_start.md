---
title: Kubernetes - Installing Gloo
weight: 2
description: Installing Gloo into an existing Kubernetes cluster.
---

If this is your first time running Gloo, you’ll need to download the command-line interface (CLI) called `glooctl` onto your local machine. You’ll use this CLI to interact with Gloo, including installing it onto your Kubernetes cluster.


### Options to Install Gloo

To install Gloo, you can use one of two options:

* [Install via the Command Line Interface (CLI) `glooctl` (recommended)](#install_cli)
* [Install via Helm](#install_helm)

### Verify Installation

* [Verify installation](#verify)

### Uninstall Gloo

* [Uninstall Gloo](#uninstall)

We highly recommend to install Gloo using the Gloo CLI as it simplifies a lot of the user experience of using Gloo.
For power users, feel free to use the underlying `yaml` configuration files directly.

This directions assume you've prepared your Kubernetes cluster appropriately. Full details on setting up your
Kubernetes cluster [here](../setup_kubernetes).

There are several options for deploying Gloo, depending on your use case and deployment platform.

* **Gateway**: (**recommended**) Gloo's full feature set is available via its v1/Gateway API. The Gateway API
is modeled on Envoy's own API with the use of opinionated defaults to make complex configurations possible,
while maintaining simplicity when required.

* **Ingress**: Gloo will support configuration the Kubernetes Ingress resource, acting as a Kubernetes
Ingress Controller.  

{{% notice note %}}
ingress objects must have the annotation `"kubernetes.io/ingress.class": "gloo"` to be processed by the Gloo Ingress.
{{% /notice %}}

* **Knative**: Gloo will integrate automatically with Knative as a cluster-level ingress for
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

{{% notice info %}}
You can install Gloo to an existing namespace by providing the `-n` option, e.g. `glooctl install gateway -n my-namespace`.
If the option is not provided, the namespace defaults to `gloo-system`.
{{% /notice %}}

### Install the Gloo Gateway to your Kubernetes Cluster using `glooctl` {#gateway}

Once your Kubernetes cluster is up and running, run the following command to deploy the Gloo Gateway to the `gloo-system` namespace:

```bash
glooctl install gateway
```

After you [verify your installation](#verify), please see [Getting Started on Kubernetes](../../../user_guides/basic_routing)
to get started using the Gloo Gateway.

### Install the Gloo Ingress Controller to your Kubernetes Cluster using `glooctl` {#ingress}

Once your Kubernetes cluster is up and running, run the following command to deploy the Gloo Ingress to the `gloo-system` namespace:

```bash
glooctl install ingress
```

After you [verify your installation](#verify), please see [Getting Started with Kubernetes Ingress](../../../user_guides/basic_ingress)
to get started using the Gloo Ingress Controller.

### Install the Gloo Knative Cluster Ingress to your Kubernetes Cluster using `glooctl` {#knative}

Once your Kubernetes cluster is up and running, run the following command to deploy Knative-Serving components to the
`knative-serving` namespace and Gloo to the `gloo-system` namespace:

```bash
glooctl install knative
```

After you [verify your installation](#verify), please see [Getting Started with Gloo and Knative](../../../user_guides/gloo_with_knative)
to use Gloo as your Knative Ingress.

---

## Install Gloo with Helm {#install_helm}

This is the recommended method for installing Gloo to your production environment as it offers rich customization to
the Gloo control plane and the proxies Gloo manages.

### Accessing the Gloo chart repository

As a first step, you have to add the Gloo repository to the list of known chart repositories:

```shell
helm repo add gloo https://storage.googleapis.com/solo-public-helm
```

You can then list all the charts in the repository by running the following command:

```shell
helm search gloo/gloo --versions
```

```noop
NAME         	CHART VERSION	APP VERSION	DESCRIPTION
gloo/gloo    	0.7.6        	           	Gloo Helm chart for Kubernetes
gloo/gloo    	0.7.5        	           	Gloo Helm chart for Kubernetes
gloo/gloo    	0.7.4        	           	Gloo Helm chart for Kubernetes
gloo/gloo    	0.7.1        	           	Gloo Helm chart for Kubernetes
gloo/gloo    	0.7.0        	           	Gloo Helm chart for Kubernetes
gloo/gloo    	0.6.24       	           	Gloo Helm chart for Kubernetes
gloo/gloo    	0.6.23       	           	Gloo Helm chart for Kubernetes
gloo/gloo    	0.6.22       	           	Gloo Helm chart for Kubernetes
gloo/gloo    	0.6.21       	           	Gloo Helm chart for Kubernetes
gloo/gloo    	0.6.20       	           	Gloo Helm chart for Kubernetes
...
```

### Choosing a deployment option

There are three deployment options for Gloo. The option to be installed is determined by the values that are passed
to the Gloo Helm chart.

* `gateway`
* `ingress`
* `knative`

#### Gateway

By default, the Gloo Helm chart is configured with the values for the `gateway` deployment. Hence, if you run:

```shell
helm install gloo/gloo --name gloo-0-7-6 --namespace my-namespace
```

Helm will install the `gateway` deployment of Gloo to the cluster your _KUBECONFIG_ is pointing to. Remember to specify
the two additional options, otherwise Helm will install Gloo to the `default` namespace and generate a funny release
`name` for it.

#### Ingress and Knative

The Gloo chart archive contains the necessary value files for each of the remaining deployment options. Run the
following command to download and extract the archive to the current directory:

```shell
helm fetch --untar=true --untardir=. gloo/gloo
```

You can then use either

* `values-ingress.yaml` or
* `values-knative.yaml`

to install the correspondent flavour of Gloo. For example, to install Gloo as your Knative Ingress you can run:

```shell
helm install gloo/gloo --name gloo-knative-0-7-6 --namespace my-namespace -f values-knative.yaml
```

After you've installed Gloo, please check out our [User Guides](../../../user_guides).

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
helm install gloo/gloo --name gloo-custom-0-7-6 --namespace my-namespace -f value-overrides.yaml
```

The install command accepts multiple value files, so if you want to override the default values for a `knative`
deployment you can run:

```shell
helm install gloo/gloo --name gloo-custom-knative-0-7-6 --namespace my-namespace -f values-knative.yaml -f value-overrides.yaml
```

The right-most file specified takes precedence (see the [Helm docs](https://helm.sh/docs/helm/#helm-install) for more
info on the `install` command).

#### List of Gloo chart values

The table below describes all the values that you can override in your custom values file.

option | type | description
--- | --- | ---
namespace.create | bool | create the installation namespace
rbac.create | bool | create rbac rules for the gloo-system service account
crds.create | bool | create CRDs for Gloo (turn off if installing with Helm to a cluster that already has Gloo CRDs)
settings.watchNamespaces | []string | whitelist of namespaces for gloo to watch for services and CRDs. leave empty to use all namespaces
settings.writeNamespace | string | namespace where intermediary CRDs will be written to, e.g. Upstreams written by Gloo Discovery.
settings.integrations.knative.enabled | bool | enable Gloo to serve as a cluster ingress controller for Knative Serving
settings.integrations.knative.proxy.image.repository | string | image name (registry/repository) for the knative proxy container. This proxy is configured automatically by Knative as the Knative Cluster Ingress.
settings.integrations.knative.proxy.image.tag | string | tag for the knative proxy container
settings.integrations.knative.proxy.image.pullPolicy | string | image pull policy for the knative proxy container
settings.integrations.knative.proxy.httpPort | string | HTTP port for the proxy
settings.integrations.knative.proxy.httpsPort | string | HTTPS port for the proxy
settings.integrations.knative.proxy.replicas | int | number of proxy instances to deploy
settings.create | bool | create a Settings CRD which configures Gloo controllers at boot time
gloo.deployment.image.repository | string | image name (registry/repository) for the gloo container. this container is the core controller of the system which watches CRDs and serves Envoy configuration over xDS
gloo.deployment.image.tag | string | tag for the gloo container
gloo.deployment.image.pullPolicy | string | image pull policy for gloo container
gloo.deployment.xdsPort | string | port where gloo serves xDS API to Envoy
gloo.deployment.replicas | int | number of gloo xds server instances to deploy
gloo.deployment.stats | bool | expose pod level stats
discovery.deployment.image.repository | string | image name (registry/repository) for the discovery container. this container adds service discovery and function discovery to Gloo
discovery.deployment.image.tag | string | tag for the discovery container
discovery.deployment.image.pullPolicy | string | image pull policy for discovery container
discovery.deployment.stats | bool | expose pod level stats
gateway.enabled | bool | enable Gloo API Gateway features
gateway.deployment.image.repository | string | image name (registry/repository) for the gateway controller container. this container translates Gloo's VirtualService CRDs to the intermediary representation used by the gloo controller
gateway.deployment.image.tag | string | tag for the gateway controller container
gateway.deployment.image.pullPolicy | string | image pull policy for the gateway controller container
gateway.deployment.stats | bool | expose pod level stats
gatewayProxy.deployment.image.repository | string | image name (registry/repository) for the gateway proxy container. this proxy receives configuration created via VirtualService CRDs
gatewayProxy.deployment.image.tag | string | tag for the gateway proxy container
gatewayProxy.deployment.image.pullPolicy | string | image pull policy for the gateway proxy container
gatewayProxy.deployment.httpPort | string | HTTP port for the proxy
gatewayProxy.deployment.replicas | int | number of gateway proxy instances to deploy
gatewayProxy.service.type | string | gateway [service type](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types). default is `LoadBalancer`
gatewayProxy.service.clusterIP | string | static clusterIP (or `None`) when `gatewayProxy.service.type` is `ClusterIP`
gatewayProxy.service.httpPort | string | HTTP port for the gateway service
gatewayProxy.service.httpsPort | string | HTTPS port for the gateway service
gatewayProxy.service.extraAnnotations | map | annotations for the gateway service
ingress.enabled | bool | enable Gloo to function as a standard Kubernetes Ingress Controller (i.e. configure via [Kubernetes Ingress objects](https://kubernetes.io/docs/concepts/services-networking/ingress/))
ingress.deployment.image.repository | string | image name (registry/repository) for the ingress controller container. this container translates [Kubernetes Ingress objects](https://kubernetes.io/docs/concepts/services-networking/ingress/) to the intermediary representation used by the gloo controller
ingress.deployment.image.tag | string | tag for the ingress controller container
ingress.deployment.image.pullPolicy | string | image pull policy for the ingress controller container
ingressProxy.deployment.image.tag | string | tag for the ingress proxy container
ingressProxy.deployment.image.repository | string | image name (registry/repository) for the ingress proxy container. this proxy receives configuration created via Kubernetes Ingress objects
ingressProxy.deployment.image.pullPolicy | string | image pull policy for the ingress proxy container
ingressProxy.deployment.httpPort | string | HTTP port for the proxy
ingressProxy.deployment.httpsPort | string | HTTPS port for the proxy
ingressProxy.deployment.replicas | int | number of ingress proxy instances to deploy

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

After you've installed Gloo, please check out our [User Guides](../../../user_guides).