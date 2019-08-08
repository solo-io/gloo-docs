---
title: "Installing Gloo for Knative"
description: How to install Gloo to run in Knative Mode on Kubernetes.
weight: 3
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

## Installing the Gloo Knative Ingress on Kubernetes

These directions assume you've prepared your Kubernetes cluster appropriately. Full details on setting up your
Kubernetes cluster [here](../cluster_setup).

### Installing on Kubernetes with `glooctl`

`glooctl`, addition to installing Gloo's Knative Ingress, will install Knative Serving components to the `knative-serving` namespace if it does not alreay exist in your cluster. This is a modified version of the Knative Serving manifest with the dependencies on Istio removed.

Once your Kubernetes cluster is up and running, run the following command to deploy the Gloo Ingress to the `gloo-system` namespace and Knative-Serving components to the `knative-serving` namespace:

```bash
glooctl install knative
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

The Gloo chart archive contains the necessary value files for the Knative deployment option. Run the
following command to download and extract the archive to the current directory:

```shell
helm fetch --untar=true --untardir=. gloo/gloo
```

Finally, install Gloo using the following command:

```shell
helm install gloo --namespace gloo-system -f gloo/values-knative.yaml
```

Gloo can be installed to a namespace of your choosing with the `--namespace` flag.

## Verify your Installation

Check that the Gloo pods and services have been created. Depending on your install option, you may see some differences
from the following example. And if you choose to install Gloo into a different namespace than the default `gloo-system`,
then you will need to query your chosen namespace instead.

```shell
kubectl get all -n gloo-system
```

```noop
NAME                                       READY   STATUS    RESTARTS   AGE
pod/clusteringress-proxy-6d786fd9f-4k5r4   1/1     Running   0          64s
pod/discovery-55b8645d77-72mbt             1/1     Running   0          63s
pod/gloo-9f9f77c8d-6sk7z                   1/1     Running   0          64s
pod/ingress-85ffc7b77b-z6lsm               1/1     Running   0          64s

NAME                           TYPE           CLUSTER-IP     EXTERNAL-IP       PORT(S)                      AGE
service/clusteringress-proxy   LoadBalancer   10.7.250.225   35.226.24.166     80:32436/TCP,443:32667/TCP   64s
service/gloo                   ClusterIP      10.7.251.47    <none>            9977/TCP                     4d10h

NAME                                   DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/clusteringress-proxy   1         1         1            1           64s
deployment.apps/discovery              1         1         1            1           63s
deployment.apps/gloo                   1         1         1            1           64s
deployment.apps/ingress                1         1         1            1           64s

NAME                                             DESIRED   CURRENT   READY   AGE
replicaset.apps/clusteringress-proxy-6d786fd9f   1         1         1       64s
replicaset.apps/discovery-55b8645d77             1         1         1       63s
replicaset.apps/gloo-9f9f77c8d                   1         1         1       64s
replicaset.apps/ingress-85ffc7b77b               1         1         1       64s
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

TODO
To begin using Gloo with Knative, check out the [Knative User Guide]({{< ref "/gloo_routing" >}}).
