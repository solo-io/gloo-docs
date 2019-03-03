---
title: Azure Kubernetes Service (AKS)
weight: 3
---

In this document we will review how to install Gloo on Azure Kubernetes Service.

## Configure kubectl

Configure `kubectl` to use with your cluster:

```bash
az aks get-credentials --resource-group glooResourceGroup --name glooCluster --admin
```

Replace the resource group and name with values appropriate for your environment. The `--admin` flag logs you into the cluster as the cluster administrator.

Validate that `kubectl` was successfully configured with:

```bash
kubectl cluster-info
```

## Install Gloo

To install Gloo, you can use one of two options:

* Install via the Command Line Interface (CLI)
* Install via Kubernetes manifest files

### Install Gloo via Command Line Interface option

To install the CLI `glooctl`, run the following. Alternatively, you can download the CLI directly
[via the github releases page](https://github.com/solo-io/gloo/releases).

```bash
curl -sL https://run.solo.io/gloo/install | sh
```

Next, add Gloo to your path with:

```bash
export PATH=$HOME/.gloo/bin:$PATH
```

Verify the CLI is installed and running correctly with:

```bash
glooctl --version
```

Now run the following to install the default `gateway` flavor of Gloo.

```bash
export LATEST_RELEASE=$(curl -s "https://api.github.com/repos/solo-io/gloo/releases/latest" \
   grep tag_name \
   sed -E 's/.*"v([^"]+)".*/\1/' )

glooctl install gateway --release $LATEST_RELEASE
```

### Kubernetes manifest install option

```bash
export LATEST_RELEASE=$(curl -s "https://api.github.com/repos/solo-io/gloo/releases/latest" \
   grep tag_name \
   sed -E 's/.*"([^"]+)".*/\1/' )

kubectl apply -f https://github.com/solo-io/gloo/releases/download/$LATEST_RELEASE/gloo-gateway.yaml
```

In this example we are installing the latest version. You can install any other released version by substituting in
desired version number.

The installation could take a few moments to fully complete depending on your network speed.

## Access from the Internet

Accessing your Gloo virtual services from the internet is easy with Azure Kubernetes Service.

Requests for Gloo's virtual services are routed via the `gateway-proxy` service. As the service type is *LoadBalancer*,
Azure will allocate a global IP address for it, and load balance requests on that IP address across the instances of the service.

To find the address of your Gloo, go to the [Kubernetes Console for your cluster](https://docs.microsoft.com/en-us/azure/aks/kubernetes-dashboard) and search for `gateway-proxy`. The allocated IP address will be listed in the *Services* box.

For Example:

![AKS Kubernetes Console](../aks-console.png "AKS Kubernetes Console")

**NOTE:** You might not see the address in the *External endpoints* column immediately, as provisioning the load balancer can take around 10 minutes.

You can now use the endpoints as your public address for requests.

## Final Notes

In addition to Gloo, usually you will also want to:

* Use a tool like *[external-dns](https://github.com/kubernetes-incubator/external-dns)* to set up DNS records for Gloo.
* Use a tool like *[cert-manager](https://github.com/jetstack/cert-manager/)* to provision SSL certificates to use with Gloo's VirtualService CRD.
