---
title: "Installing Gloo as an Ingress Controller"
description: How to install Gloo to run in Ingress Mode on Kubernetes.
weight: 4
---

## Install command line tool (CLI)

The `glooctl` command line provides useful functions to install, configure, and debug Gloo, though it is not required to use Gloo.

To install `glooctl` using the [Homebrew](https://brew.sh) package manager, run the following.

```shell
brew install solo-io/tap/gloo
```

To install on any platform run the following.

```bash
curl -sL https://run.solo.io/gloo/install | sh
```

You can download `glooctl` directly via the GitHub releases page. You need to add `glooctl` to your path after downloading.


```bash
export PATH=$HOME/.gloo/bin:$PATH
```

Verify the CLI is installed and running correctly with:

```bash
glooctl --version
```

## Installing the Gloo Ingress Controller on Kubernetes

These directions assume you've prepared your Kubernetes cluster appropriately. Full details on setting up your
Kubernetes cluster [here](../cluster_setup).

### Installing on Kubernetes with `glooctl`

Once your Kubernetes cluster is up and running, run the following command to deploy the Gloo Ingress Controller to the `gloo-system` namespace:

```bash
glooctl install ingress
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

The Gloo chart archive contains the necessary value files for the Ingress deployment option. Run the
following command to download and extract the archive to the current directory:

```shell
helm fetch --untar=true --untardir=. gloo/gloo
```

Finally, install Gloo using the following command:

```shell
helm install gloo --namespace gloo-system -f gloo/values-ingress.yaml
```

Gloo can be installed to a namespace of your choosing with the `--namespace` flag.

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

To begin using Gloo with the Kubernetes Ingress API, check out the [Ingress Controller guide](../../../user_guides/basic_ingress).
