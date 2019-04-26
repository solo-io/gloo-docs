---
title: Installing SuperGloo
menuTitle: Installation
description: How to install SuperGloo.
weight: 10
---

## Installing SuperGloo

### 1. Install CLI `supergloo`

To install the CLI, run the following.

```bash
curl -sL https://run.solo.io/supergloo/install | sh
```

Alternatively, you can download the CLI directly
[via the github releases page](https://github.com/solo-io/supergloo/releases).

Next, add SuperGloo to your path, for example:

```bash
export PATH=$HOME/.supergloo/bin:$PATH
```

Verify the CLI is installed and running correctly with:

```bash
supergloo --version
```

#### 2. Install the SuperGloo Controller to your Kubernetes Cluster using `supergloo init`

Once your Kubernetes cluster is up and running, run the following command to deploy the SuperGloo Controller and Discovery pods to the `supergloo-system` namespace:

```bash
supergloo init

installing supergloo version 0.3.14
using chart uri https://storage.googleapis.com/supergloo-helm/charts/supergloo-0.3.14.
tgz
configmap/sidecar-injection-resources created
serviceaccount/supergloo created
serviceaccount/discovery created
serviceaccount/mesh-discovery created
clusterrole.rbac.authorization.k8s.io/discovery created
clusterrole.rbac.authorization.k8s.io/mesh-discovery created
clusterrolebinding.rbac.authorization.k8s.io/supergloo-role-binding created
clusterrolebinding.rbac.authorization.k8s.io/discovery-role-binding created
clusterrolebinding.rbac.authorization.k8s.io/mesh-discovery-role-binding created
deployment.extensions/supergloo created
deployment.extensions/discovery created
deployment.extensions/mesh-discovery created
install successful!
```

You can see the kubernetes YAML `supergloo` is installing to your cluster without installing
by running `supergloo init --dry-run`.

---
**NOTE:** You can install SuperGloo to an existing namespace by providing the `-n` option. If the option is not provided, the namespace defaults to `supergloo-system`.

```bash
supergloo init -n my-namespace
```

---

Check that the SuperGloo and Discovery pods have been created:

```bash
kubectl get all -n supergloo-system
```

```noop
NAME                                 READY   STATUS    RESTARTS   AGE
pod/discovery-68df78f9c-rk2w4        1/1     Running   0          2m49s
pod/mesh-discovery-bc9fbcb7f-z84r9   1/1     Running   0          2m49s
pod/supergloo-59445698c5-p2fvm       1/1     Running   0          2m49s

NAME                             DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/discovery        1         1         1            1           2m49s
deployment.apps/mesh-discovery   1         1         1            1           2m49s
deployment.apps/supergloo        1         1         1            1           2m49s

NAME                                       DESIRED   CURRENT   READY   AGE
replicaset.apps/discovery-68df78f9c        1         1         1       2m49s
replicaset.apps/mesh-discovery-bc9fbcb7f   1         1         1       2m49s
replicaset.apps/supergloo-59445698c5       1         1         1       2m49s
```

## Next steps

Now that you've successfully installed SuperGloo, let's put it to work in our tutorial, [installing a mesh with SuperGloo](../mesh/install-istio)

## Uninstall

To uninstall SuperGloo and all related components, simply run the following:

```bash
supergloo init --dry-run | kubectl delete -f -
```

If you installed SuperGloo to a different namespace, you will have to specify that namespace using the `-n` option:

```bash
supergloo init --dry-run -n my-namespace | kubectl delete -f -
```

<!-- end -->
