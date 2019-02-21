---
title: Installing Gloo with Helm
weight: 1
---

This document outlines instructions for the setup and configuration of Gloo using Helm. This is the recommended method 
for installing Gloo to your production environment as it offers rich customization to the Gloo control plane and the 
proxies Gloo manages.


## Accessing the Gloo chart repository
As a first step, you have to add the Gloo repository to the list of known chart repositories:

```bash
helm repo add gloo https://storage.googleapis.com/solo-public-helm
```

You can then list all the charts in the repository by running the following command:

```bash
helm search gloo/gloo --versions  

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


## Choosing a deployment option
As we saw in the [**previous section**](../#2-choosing-a-deployment-option), there are three deployment options for Gloo:

1. gateway
2. ingress
3. knative

The option to be installed is determined by the values that are passed to the Gloo Helm chart. 


### Gateway
By default, the Gloo Helm 
chart is configured with the values for the `gateway` deployment. Hence, if you run 

```bash
helm install gloo/gloo --name gloo-0.7.6 --namespace my-namespace
```

Helm will install the `gateway` deployment of Gloo to the cluster your _KUBECONFIG_ is pointing to. Remember to specify 
the two additional options, otherwise Helm will install Gloo to the `default` namespace and generate a funny release 
`name` for it.


### Ingress & Knative
The Gloo chart archive contains the necessary value files for each of the remaining deployment options. Run the 
following command to download and extract the archive to the current directory:

```bash
helm fetch --untar=true --untardir=. gloo/gloo
```

You can then use either

- `values-ingress.yaml` or
- `values-knative.yaml`

to install the correspondent flavour of Gloo. For example, to install Gloo as your Knative Ingress you can run:

```bash
helm install gloo/gloo --name gloo-knative-0.7.6 --namespace my-namespace -f values-knative.yaml
```


## Customizing your installation
You can customize the Gloo installation by providing your own value file.

For example, you can create a file named `value-overrides.yaml` with the following content:

```yaml
rbac:
  create: false
settings:
  writeNamespace: my-custom-namespace
``` 

and use it to override default values in the Gloo Helm chart:

```bash
helm install gloo/gloo --name gloo-custom-0.7.6 --namespace my-namespace -f value-overrides.yaml 
```

The install command accepts multiple value files, so if you want to override the default values for a `knative` 
deployment you can run:

```bash
helm install gloo/gloo --name gloo-custom-knative-0.7.6 --namespace my-namespace -f values-knative.yaml -f value-overrides.yaml
```

The right-most file specified takes precedence (see the [Helm docs](https://docs.helm.sh/helm/#helm-install) for more 
info on the `install` command).

### List of Gloo chart values
The table below describes all the values that you can override in your custom values file.

option | type | description
--- | --- | ---
namespace.create | bool | create the installation namespace
rbac.create | bool | create rbac rules for the gloo-system service account
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
