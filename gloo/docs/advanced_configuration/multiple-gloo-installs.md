---
title: Installing Gloo to Multiple Namespaces
weight: 20
description: Multi-tenant Gloo installations by installing to multiple namespaces
---

## Motivation


In the default deployment scenario, a single deployment of the Gloo control plane and Envoy proxy are installed for the entire cluster. However, in some cases, it may be desirable to deploy multiple instances of the Gloo control plane and proxies in a single cluster.

This is useful when multiple tenants or applications want control over their own instance of Gloo. Some deployment scenarios may involve a Gloo-per-application architecture. Additionally, different Gloo instances living in their own namespace may be given different levels of RBAC permissions.

In this document, we will review how to deploy multiple instances of Gloo to their own namespaces within a single Kubernetes cluster. 

## Scoping Gloo to specific namespaces

When using the default installation, Gloo will watch all namespaces for Kubernetes services and Gloo CRDs. This means that any Kubernetes service can be a destination for any VirtualService in the cluster.

Gloo can be configured to only watch specific namespaces, meaning Gloo will not see services and CRDs in any namespaces other than those provided in the [`watchNamespaces` setting]({{< ref "/api/github.com/solo-io/gloo/projects/gloo/api/v1/settings.proto.sk.md#settings" >}}).

By leveraging this option, we can install Gloo to as many namespaces we need, ensuring that the `watchNamespaces` do not overlap.

> Note: `watchNamespaces` can be shared between Gloo instances, so long as any Virtual Services are not written to a shared namespace. When this happens, both Gloo instances will attempt to apply the same routing config, which can cause domain conflicts.

Currently, installing Gloo with specific `watchNamespaces` requires installation via the Helm chart.

## Installing Namespace-Scoped Gloo with Helm

In this section we'll deploy Gloo twice, each instance to a different namespace, with two different Helm value files.

Create a file named `gloo1-overrides.yaml` and paste the following inside:

```yaml
settings:
  create: true
  writeNamespace: gloo1
  watchNamespaces:
  - default
  - gloo1
```

Now, let's install Gloo:

```bash
# create the namespace for our first gloo deployment
kubectl create ns gloo1

# if you have not already added the gloo helm repo
helm repo add gloo https://storage.googleapis.com/solo-public-helm

# download the gloo chart with helm cli. this is required 
# as helm template does not support remote repos
# https://github.com/helm/helm/issues/4527
helm fetch --untar --untardir . 'gloo/gloo'

# deploy gloo resources to gloo1 with our value overrides
helm template gloo --namespace gloo1 --values gloo1-overrides.yaml  | k apply -f - -n gloo1

```

Check that gloo pods are running: 

```bash
kubectl get pod -n gloo1
```

```bash
NAME                             READY   STATUS    RESTARTS   AGE
discovery-798cdd5499-z7rrt       1/1     Running   0          37s
gateway-5fc999b847-jf4xp         1/1     Running   0          32s
gateway-proxy-67f4c7dfb6-hc5kg   1/1     Running   0          27s
gloo-dd5bcdc8f-bvtjh             1/1     Running   0          39s
```

And we should see that Gloo is only creating upstreams from services in `default` and `gloo1`:

```bash
kubectl get us -n gloo1                                              
```

```bash
NAME                      AGE
default-kubernetes-443    1h
gloo1-gateway-proxy-443   1h
gloo1-gateway-proxy-80    1h
gloo1-gloo-9977           1h
```

Let's repeat the above process, substituting `gloo2` for `gloo1`:

Create a file named `gloo2-overrides.yaml` and paste the following inside:

```yaml
settings:
  create: true
  writeNamespace: gloo2
  watchNamespaces:
  - default
  - gloo2
```

Now, let's install Gloo for the second time:

```bash
# create the namespace for our second gloo deployment
kubectl create ns gloo2

# deploy gloo resources to gloo2 with our value overrides
helm template gloo --namespace gloo2 --values gloo2-overrides.yaml  | k apply -f - -n gloo2

```

Check that gloo pods are running: 

```bash
kubectl get pod -n gloo2
```

```bash
NAME                             READY   STATUS    RESTARTS   AGE
discovery-798cdd5499-kzmkc       1/1     Running   0          8s
gateway-5fc999b847-pn2tk         1/1     Running   0          8s
gateway-proxy-67f4c7dfb6-284wv   1/1     Running   0          8s
gloo-dd5bcdc8f-krp5p             1/1     Running   0          9s
```

And we should see that the second installation of Gloo is only creating upstreams from services in `default` and `gloo2`:

```bash
kubectl get us -n gloo2
```

```bash
NAME                      AGE
default-kubernetes-443    53s
gloo2-gateway-proxy-443   53s
gloo2-gateway-proxy-80    53s
gloo2-gloo-9977           53s
```

And that's it! We can now create routes for Gloo #1 by creating our Virtual Services in the `gloo1` namespace, and routes for Gloo #2 by creating Virtual Services in the `gloo2` namespace. We can add `watchNamespaces` to our liking; the only catch is that a Virtual Service which lives in a shared namespace will be applied to both gateways (which can lead to undesired behavior if this was not the intended effect).

> Warning: When uninstalling a single instance of Gloo when multiple instances are installed, you should only delete the namespace into which that instance is installed. Running `glooctl uninstall` can cause cluster-wide resources to be deleted, which will break any remaining Gloo installation in your cluster
