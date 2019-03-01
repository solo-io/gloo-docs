---
title: Google Kubernetes Engine (GKE)
weight: 2
---

In this document we will review how to install Gloo on Google Kubernetes Engine.

## Configure kubectl

Configure `kubectl` to use with your cluster:

```bash
gcloud container clusters get-credentials YOUR-CLUSTER-NAME --zone ZONE --project YOUR-PROJECT-ID
```

Validate that `kubectl` was successfully configured with:

```bash
kubectl cluster-info
```

## Give yourself cluster admin role

To be able to install Gloo, it needs to be able to discovery your Kubernetes services. You'll need `clusteradmin` role for that.

```bash
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin \
  --user $(gcloud config get-value account)
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
glooctl install gateway
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

Accessing your Gloo virtual services from the internet is easy with Google Kubernetes Engine.

Requests for Gloo's virtual services are routed via the `gateway-proxy` service. As the service type is *LoadBalancer*,
Google will allocate a global IP address for it, and load balance requests on that IP address across the instances of the service.

To find the address of your Gloo, go to the *Services* tab of your GKE, add `name: gateway-proxy` to the search filters.
The allocated address will be under the *Endpoints* column.

For Example:

![gke services](../gke.png "GKE Services")

*NOTE:* You might not see see the address in the endpoint column immediately, as provisioning the cloud load balancer
can take around 10 minutes. Try waiting a few minutes, and clicking the REFRESH link on the top of the page.

You can now use the endpoints as your public address for requests.

## Final Notes

In addition to Gloo, usually you will also want to:

* Use a tool like *[external-dns](https://github.com/kubernetes-incubator/external-dns)* to setup DNS Record for Gloo.
* Use a tool like *[cert-manager](https://github.com/jetstack/cert-manager/)* to provision SSL certificates to use with Gloo's VirtualService CRD.
