---
title: "Installing Gloo Gateway on Kubernetes"
description: How to install Gloo to run in Gateway Mode on Kubernetes (Default).
weight: 2
---

## Install command line tool (CLI)

The `glooctl` command line provides useful functions to install, configure, and debug Gloo, though it is not required to use Gloo.

* To install `glooctl` using the [Homebrew](https://brew.sh) package manager, run the following.

  ```shell
  brew install solo-io/tap/glooctl
  ```

* To install on any platform run the following.

  ```bash
  curl -sL https://run.solo.io/gloo/install | sh

  export PATH=$HOME/.gloo/bin:$PATH
  ```

* You can download `glooctl` directly via the GitHub releases page. You need to add `glooctl` to your system's `PATH` after downloading.

Verify the CLI is installed and running correctly with:

```bash
glooctl --version
```

```shell
glooctl community edition version 0.13.29
```

## Installing the Gloo Gateway on Kubernetes

These directions assume you've prepared your Kubernetes cluster appropriately. Full details on setting up your
Kubernetes cluster [here](../../cluster_setup).

### Installing on Kubernetes with `glooctl`

Once your Kubernetes cluster is up and running, run the following command to deploy the Gloo Gateway to the `gloo-system` namespace:

```bash
glooctl install gateway
```

> Note: You can run the command with the flag `--dry-run` to output
the Kubernetes manifests (as `yaml`) that `glooctl` will
apply to the cluster instead of installing them.

### Installing on Kubernetes with Helm


This is the recommended method for installing Gloo to your production environment as it offers rich customization to
the Gloo control plane and the proxies Gloo manages.

As a first step, you have to add the Gloo repository to the list of known chart repositories:

```shell
helm repo add gloo https://storage.googleapis.com/solo-public-helm
```

Finally, install Gloo using the following command:

```shell
helm install gloo/gloo --namespace my-namespace
```

#### Customizing your installation with Helm

You can customize the Gloo installation by providing your own value file.

For example, you can create a file named `value-overrides.yaml` with the following content:

```yaml
rbac:
  # do not create kubernetes rbac resources
  create: false
settings:
  # configure gloo to write generated custom resources to a custom namespace
  writeNamespace: my-custom-namespace
```

and use it to override default values in the Gloo Helm chart:

```shell
helm install gloo/gloo --name gloo-custom-0-7-6 --namespace my-namespace -f value-overrides.yaml
```

#### List of Gloo Helm chart values

The table below describes all the values that you can override in your custom values file.

| option                                                    | type     | description                                                                                                                                                                                                                                                    |
| --------------------------------------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| namespace.create                                          | bool     | create the installation namespace                                                                                                                                                                                                                              |
| rbac.create                                               | bool     | create rbac rules for the gloo-system service account                                                                                                                                                                                                          |
| crds.create                                               | bool     | create CRDs for Gloo (turn off if installing with Helm to a cluster that already has Gloo CRDs)                                                                                                                                                                |
| settings.watchNamespaces                                  | []string | whitelist of namespaces for gloo to watch for services and CRDs. leave empty to use all namespaces                                                                                                                                                             |
| settings.writeNamespace                                   | string   | namespace where intermediary CRDs will be written to, e.g. Upstreams written by Gloo Discovery.                                                                                                                                                                |
| settings.integrations.knative.enabled                     | bool     | enable Gloo to serve as a cluster ingress controller for Knative Serving                                                                                                                                                                                       |
| settings.integrations.knative.proxy.image.repository      | string   | image name (registry/repository) for the knative proxy container. This proxy is configured automatically by Knative as the Knative Cluster Ingress.                                                                                                            |
| settings.integrations.knative.proxy.image.tag             | string   | tag for the knative proxy container                                                                                                                                                                                                                            |
| settings.integrations.knative.proxy.image.pullPolicy      | string   | image pull policy for the knative proxy container                                                                                                                                                                                                              |
| settings.integrations.knative.proxy.httpPort              | string   | HTTP port for the proxy                                                                                                                                                                                                                                        |
| settings.integrations.knative.proxy.httpsPort             | string   | HTTPS port for the proxy                                                                                                                                                                                                                                       |
| settings.integrations.knative.proxy.replicas              | int      | number of proxy instances to deploy                                                                                                                                                                                                                            |
| settings.create                                           | bool     | create a Settings CRD which configures Gloo controllers at boot time                                                                                                                                                                                           |
| gloo.deployment.image.repository                          | string   | image name (registry/repository) for the gloo container. this container is the core controller of the system which watches CRDs and serves Envoy configuration over xDS                                                                                        |
| gloo.deployment.image.tag                                 | string   | tag for the gloo container                                                                                                                                                                                                                                     |
| gloo.deployment.image.pullPolicy                          | string   | image pull policy for gloo container                                                                                                                                                                                                                           |
| gloo.deployment.xdsPort                                   | string   | port where gloo serves xDS API to Envoy                                                                                                                                                                                                                        |
| gloo.deployment.replicas                                  | int      | number of gloo xds server instances to deploy                                                                                                                                                                                                                  |
| gloo.deployment.stats                                     | bool     | expose pod level stats                                                                                                                                                                                                                                         |
| discovery.deployment.image.repository                     | string   | image name (registry/repository) for the discovery container. this container adds service discovery and function discovery to Gloo                                                                                                                             |
| discovery.deployment.image.tag                            | string   | tag for the discovery container                                                                                                                                                                                                                                |
| discovery.deployment.image.pullPolicy                     | string   | image pull policy for discovery container                                                                                                                                                                                                                      |
| discovery.deployment.stats                                | bool     | expose pod level stats                                                                                                                                                                                                                                         |
| gateway.enabled                                           | bool     | enable Gloo API Gateway features                                                                                                                                                                                                                               |
| gateway.upgrade                                           | bool     | Deploy a Job to convert (but not delete) v1 Gateway resources to v2 and not add a "live" label to the gateway-proxy deployment's pod template. This allows for canary testing of gateway-v2 alongside an existing instance of gloo running with v1 gateway resources and controllers.                                                                                                                                                                                                                              |
| gateway.deployment.image.repository                       | string   | image name (registry/repository) for the gateway controller container. this container translates Gloo's VirtualService CRDs to the intermediary representation used by the gloo controller                                                                     |
| gateway.deployment.image.tag                              | string   | tag for the gateway controller container                                                                                                                                                                                                                       |
| gateway.deployment.image.pullPolicy                       | string   | image pull policy for the gateway controller container                                                                                                                                                                                                         |
| gateway.deployment.stats                                  | bool     | expose pod level stats                                                                                                                                                                                                                                         |
| gatewayProxies[].gatewayProxy.podTemplate.image.repository| string   | image name (registry/repository) for the gateway proxy container. this proxy receives configuration created via VirtualService CRDs                                                                                                                            |
| gatewayProxies[].gatewayProxy.podTemplate.image.tag       | string   | tag for the gateway proxy container                    |
| gatewayProxies[].gatewayProxy.podTemplate.image.pullPolicy |  string   |  image pull policy for the gateway proxy container       |
| gatewayProxies[].gatewayProxy.podTemplate.httpPort        | string   | HTTP port for the proxy                                 |
| gatewayProxies[].gatewayProxy.podTemplate.stats           | bool      | number of gateway proxy instances to deploy             |
| gatewayProxies[].gatewayProxy.podTemplate.nodeSelector    | map[string]string      | label selector for nodes                   |
| gatewayProxies[].gatewayProxy.podTemplate.nodeName        | string      | name of node to run on                               |
| gatewayProxies[].gatewayProxy.kind                        | object   | Kind has 2 child ojects `DaemonSet` and `Deployment`. Depending on which value is set the `gateway-proxy` pod will be deployed by a `DaemonSet` controller or a `Deployment` controller. The default is `Deployment`                                                        |
| gatewayProxies[].gatewayProxy.kind.deployment.replicas    | int      | number of gateway proxy instances to deploy              |
| gatewayProxies[].gatewayProxy.kind.daemonSet.hostPort     | bool     | whether or not to enable host networking on the gateway-proxy pod. Only relevant when running as a DaemonSet                                                                                                                                                     |
| gatewayProxies[].gatewayProxy.service.type                | string   | gateway [service type](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types). default is `LoadBalancer`                                                                                                          |
| gatewayProxies[].gatewayProxy.service.clusterIP           | string   | static clusterIP (or `None`) when `gatewayProxies[].gatewayProxy.service.type` is `ClusterIP`                                                                                                                                                                  |
| gatewayProxies[].gatewayProxy.service.httpPort            | string   | HTTP port for the gateway service                                                                                                                                                                                                                              |
| gatewayProxies[].gatewayProxy.service.httpsPort           | string   | HTTPS port for the gateway service                                                                                                                                                                                                                             |
| gatewayProxies[].gatewayProxy.service.extraAnnotations    | map      | annotations for the gateway service                                                                                                                                                                                                                            |
| ingress.enabled                                           | bool     | enable Gloo to function as a standard Kubernetes Ingress Controller (i.e. configure via [Kubernetes Ingress objects](https://kubernetes.io/docs/concepts/services-networking/ingress/))                                                                        |
| ingress.deployment.image.repository                       | string   | image name (registry/repository) for the ingress controller container. this container translates [Kubernetes Ingress objects](https://kubernetes.io/docs/concepts/services-networking/ingress/) to the intermediary representation used by the gloo controller |
| ingress.deployment.image.tag                              | string   | tag for the ingress controller container                                                                                                                                                                                                                       |
| ingress.deployment.image.pullPolicy                       | string   | image pull policy for the ingress controller container                                                                                                                                                                                                         |
| ingressProxy.deployment.image.tag                         | string   | tag for the ingress proxy container                                                                                                                                                                                                                            |
| ingressProxy.deployment.image.repository                  | string   | image name (registry/repository) for the ingress proxy container. this proxy receives configuration created via Kubernetes Ingress objects                                                                                                                     |
| ingressProxy.deployment.image.pullPolicy                  | string   | image pull policy for the ingress proxy container                                                                                                                                                                                                              |
| ingressProxy.deployment.httpPort                          | string   | HTTP port for the proxy                                                                                                                                                                                                                                        |
| ingressProxy.deployment.httpsPort                         | string   | HTTPS port for the proxy                                                                                                                                                                                                                                       |
| ingressProxy.deployment.replicas                          | int      | number of ingress proxy instances to deploy            |

---
## Verify your Installation

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

---

## Uninstall {#uninstall}

To uninstall Gloo and all related components, simply run the following.

```shell
glooctl uninstall
```

If you installed Gloo to a different namespace, you will have to specify that namespace using the `-n` option:

```shell
glooctl uninstall -n my-namespace
```

## Next Steps

After you've installed Gloo, please check out our [User Guides]({{< ref "/gloo_routing" >}}).
