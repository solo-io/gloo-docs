---
title: "Mesh Discovery"
weight: 2
---

# Overview

Mesh discovery is the ability to discovery service meshes which are running in the cluster to which mesh
discovery is deployed. This capability is currently shipped with SuperGloo by default, but in the future
will be available as a standalone feature.

Currently supported meshes for Discovery:

- Istio

# Architecture

Mesh discovery, similar to other solo.io projects, uses an event loop based architecure to watch Kubernetes
resources to create/update those resources. In this case we are interested in three resources:

- [Mesh](../../v1/github.com/solo-io/supergloo/api/v1/mesh.proto.sk)
- [Install](../../v1/github.com/solo-io/supergloo/api/v1/install.proto.sk)
- [Pod](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.11/#pod-v1-core) (Kubernetes resource)

More information about these resources can be found by clicking the links above.

At its core mesh discovery monitors these resources and takes actions based on certain heuristics. These heuristics
vary slightly by the type of mesh we are trying to discover, but the concept is similar. For example, in the case of Istio:
mesh discovery watches for the existence of a deployment named istio-pilot and discovers the deployed Istio version based
on Pilot's image tag.

#### Discovering Mesh Configuration

In order to observe/discover the existing mesh configuration, mesh discovery requires the ability to monitor custom resources (CRDs)
on a per mesh basis. In order to accomplish this mesh discovery creates new watches for mesh specific resources when/if a mesh
CRD for a given mesh is found. For instance, if an Istio mesh is discovered, and an Istio mesh CRD is created, then mesh
discovery will begin to monitor Istio specific resources in order to gather more fine grained details about the particular
Istio deployment.

{{<mermaid>}}
graph TB;
    cli1 ---|writes| crd2
    subgraph cli/kubectl
        cli1[User/System]
    end
    md2 ---|spanws| md3
    md1 ---|writes| crd1
    md2 ---|reads| crd1
    md1 ---|reads| crd2
    subgraph mesh-discovery
        md1[Discovery Event Loop]
        md2[Discovery Registration Loop]
        md3[Istio Config Loop]
    end
    sg1 ---|reads| crd2
    subgraph custom-resources
        crd1(Mesh CRD)
        crd2(Install CRD)
    end
    subgraph supergloo
        sg1[Install Event Loop]
    end
{{< /mermaid >}}

The above diagram is an approximation of this system working in practice. The lines do not represent order exactly as all of the parts
of the system are running concurrently, but it still gives an idea of how the different pieces are created and consumed.

## Mesh Discovery In Practice

As stated above mesh discovery currently requires SuperGloo to run, so in order to test out mesh discovery we must first install SuperGloo.
To install SuperGloo refer to the previous tutorial on [installation](../../installation). Once the SuperGloo cli is installed and SuperGloo is
running we are ready to begin.

If Istio is already installed on your system feel free to skip this next step.

#### Install Istio via helm

To install Istio we will use the helm chart from their official distribution. For the purposes of this demo we are going to use Istio `1.0.x`.

```bash
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=1.0.6 sh -
```

Once this download has completed apply the helm chart into your cluster

```bash
helm template install/kubernetes/helm/istio --name istio --namespace istio-system | kubectl apply -f -
```

To check that Istio is running:

```bash
$ kubectl get pods --all-namespaces
```

```noop
NAMESPACE          NAME                                      READY   STATUS      RESTARTS   AGE
istio-system       istio-citadel-6559b9697b-wgcqm            1/1     Running     0          88s
istio-system       istio-cleanup-secrets-lw9xm               0/1     Completed   0          89s
istio-system       istio-egressgateway-5dd6dbb89f-pb8bn      1/1     Running     0          89s
istio-system       istio-galley-7cd7dc49f9-m95ws             1/1     Running     0          89s
istio-system       istio-ingressgateway-947b9cd66-bq5fs      1/1     Running     0          89s
istio-system       istio-pilot-7786dc9c69-p7cjn              2/2     Running     0          88s
istio-system       istio-policy-6c54647778-zmtb8             2/2     Running     0          88s
istio-system       istio-security-post-install-rlw9d         0/1     Completed   0          89s
istio-system       istio-sidecar-injector-75fddbd5c9-97rs2   1/1     Running     0          88s
istio-system       istio-telemetry-68c686dd4b-4q9ml          2/2     Running     0          88s
istio-system       prometheus-578b7dcfdc-gnx2x               1/1     Running     0          88s
kube-system        coredns-fb8b8dccf-dl2bj                   1/1     Running     0          28h
kube-system        coredns-fb8b8dccf-x966j                   1/1     Running     0          28h
kube-system        etcd-minikube                             1/1     Running     0          28h
kube-system        kube-addon-manager-minikube               1/1     Running     0          28h
kube-system        kube-apiserver-minikube                   1/1     Running     0          28h
kube-system        kube-controller-manager-minikube          1/1     Running     0          28h
kube-system        kube-proxy-cdmpd                          1/1     Running     0          28h
kube-system        kube-scheduler-minikube                   1/1     Running     0          28h
kube-system        storage-provisioner                       1/1     Running     0          28h
supergloo-system   discovery-58d85b9d9f-nkkpk                1/1     Running     0          9s
supergloo-system   mesh-discovery-7b69d48d7c-f8cmt           1/1     Running     0          9s
supergloo-system   supergloo-84f85b459c-sfvdg                1/1     Running     0          9s
```

#### Discovered Mesh CRD

Once Istio and SuperGloo are running in the cluster we can check for the mesh CRD:

```bash
kubectl get mesh --namespace supergloo-system --output yaml
```

```yaml
apiVersion: supergloo.solo.io/v1
kind: Mesh
metadata:
  generation: 2
  name: istio-istio-system
  namespace: supergloo-system
spec:
  discoveryMetadata:
    injectedNamespaceLabel: istio-injection
    installationNamespace: istio-system
    meshVersion: 1.0.6
  istio:
    installationNamespace: istio-system
    istioVersion: 1.0.6
status:
  reported_by: istio-config-reporter
  state: 1
```

As you can see SuperGloo figured out the location and version of Istio, and now we can go ahead and apply SuperGloo rules to our mesh.
For further tutorials using SuperGloo with our mesh, check the [tutorials](../tutorials) section for in depth tutorials on configuring the
mesh using SuperGloo.
