---
title: "Installing a Mesh"
weight: 2
---

# Overview

SuperGloo can be used to install, upgrade, and uninstall a supported mesh.

Currently supported meshes for installation:

- Istio

## Installing Istio with SuperGloo

First, ensure that SuperGloo has been initialized in your kubernetes cluster via `supergloo init` or the 
[Supergloo Helm Chart](https://github.com/solo-io/supergloo/tree/master/install/helm/supergloo). See the [installation
instructions](install) for detailed instructions on installing SuperGloo.

Once SuperGloo has been installed, we'll create an Install CRD with configuration parameters which will then
trigger SuperGloo to begin the mesh installation.

This can be done in one of two ways:

#### Option 1: Using the `supergloo` CLI:

```bash
supergloo install istio --name istio --installation-namespace istio-system --mtls=true --auto-inject=true
```

See `supergloo install istio --help` for the full list of installation options for istio.


#### Option 2: Using `kubectl apply` on a yaml file:

```yaml
cat << EOF | kubectl apply -f -
apiVersion: supergloo.solo.io/v1
kind: Install
metadata:
name: my-istio
spec:
istio:
  enableAutoInject: true
  enableMtls: true
  installGrafana: true
  installJaeger: true
  installPrometheus: true
  installationNamespace: istio-system
  istioVersion: 1.0.6  
EOF
```

Once you've created the Install CRD, you can track the progress of the Istio installation:

```bash
kubectl get pod -n istio-system --watch

NAME                                      READY     STATUS              RESTARTS   AGE
grafana-7f6cd4bf56-xst2n                  1/1       Running             0          27s
istio-citadel-796c94878b-59gw6            1/1       Running             0          26s
istio-cleanup-secrets-xd6f8               0/1       Completed           0          27s
istio-galley-6c68c5dbcf-z6j5k             1/1       Running             0          27s
istio-pilot-c5dddb4b9-nb6fd               2/2       Running             0          26s
istio-policy-977d74ff4-669vk              2/2       Running             0          27s
istio-sidecar-injector-6d8f88c98f-5f58t   1/1       Running             0          26s
istio-telemetry-5f79796bf6-fl4sn          2/2       Running             0          27s
istio-tracing-7596597bd7-lc92t            1/1       Running             0          26s
prometheus-76db5fddd5-55r6d               1/1       Running             0          26s

```


## Testing the Install

Test out mTLS

Let's deploy the [Istio Bookinfo](https://istio.io/docs/examples/bookinfo/) example with automatic sidecar injection enabled. 

First, enable autoamtic sidecar injection on the default namespace (or any namespace of your choosing):

```bash
kubectl label namespace default istio-injection=enabled
```

Next, create the bookinfo deployments and services:

```bash
kubectl apply -n default -f \
  https://raw.githubusercontent.com/istio/istio/1.0.6/samples/bookinfo/platform/kube/bookinfo.yaml
```

We should be up and running in a few minutes:

```bash
kubectl get pod -n default --watch

NAME                             READY     STATUS    RESTARTS   AGE
details-v1-6764bbc7f7-k4rhk      2/2       Running   0          27s
productpage-v1-54b8b9f55-sxxnw   2/2       Running   0          27s
ratings-v1-7bc85949-kh4f9        2/2       Running   0          27s
reviews-v1-fdbf674bb-z467l       2/2       Running   0          27s
reviews-v2-5bdc5877d6-gvgns      2/2       Running   0          27s
reviews-v3-dd846cc78-55wr5       2/2       Running   0          27s
```

We should see `2/2` containers are `READY`, since one of those containers is the sidecar injected by Istio.


Next we'll deploy a `sleep` pod which we can use to execute commands inside
the cluster. The first time we deploy, we'll run it outside the mesh to see
what happens when we try to connect to mtls-enabled services.

```bash
# create a new namespace without injection enabled
kubectl create ns not-injected
kubectl apply -n not-injected -f \
  https://raw.githubusercontent.com/istio/istio/1.0.6/samples/sleep/sleep.yaml
``` 

We can now run a `curl` command via `kubectl exec` to simulate communication
within our cluster:

```bash
kubectl exec -n not-injected sleep-7ffd5cc988-4wrz2 -- curl reviews.default.svc.cluster.local:9080/reviews/1

curl: (56) Recv failure: Connection reset by peer
command terminated with exit code 56
```

We won't be able to connect to `reviews` over normal http. Even if we try with HTTPS enabled, skippinng server certificate verification...

```bash
kubectl exec -n not-injected sleep-7ffd5cc988-4wrz2 -- curl https://reviews.default.svc.cluster.local:9080/reviews/1 --insecure

curl: (35) error:1401E410:SSL routines:CONNECT_CR_FINISHED:sslv3 alert handshake failure
command terminated with exit code 35
```

we'll see that the client cannot complete the SSL handshake. 

Now let's try with a pod that's been injected with the Istio sidecar. This time, deploy `sleep` to the default namespace where it'll get automatically injected with the sidecar:

```bash
kubectl apply -n default -f https://raw.githubusercontent.com/istio/istio/1.0.6/samples/sleep/sleep.yaml
``` 

Execute the same `kubectl exec` command as before, but this time using the pod 
in the default namespace:

```bash
kubectl exec -n default sleep-7ffd5cc988-k72pg curl reviews.default.svc.cluster.local:9080/reviews/1

{"id": "1","reviews": [{  "reviewer": "Reviewer1",  "text": "An extremely entertaining play by Shakespeare. The slapstick humour is r100   295  100   295    0     0    215      0  0:00:01  0:00:01 --:--:--   215ning. The play lacks thematic depth when compared to other plays by Shakespeare."}]}
```

Cool! We got a JSON response. We've now demonstrated that only pods inside the mesh are able to communicate when mTLS is enabled.

To tear everything down from this demo:

```bash
kubectl delete -n default -f https://raw.githubusercontent.com/istio/istio/1.0.6/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl delete ns not-injected
```

## Uninstalling Istio

If the `disabled` field is set to `true` on the install CRD. Doing so, again we have two options:

#### Option 1: Using the `supergloo` CLI:

```bash
supergloo uninstall --name istio
```


#### Option 2: Using `kubectl edit` and set `spec.disabled: true`:

```yaml
kubectl edit install istio

# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: supergloo.solo.io/v1
kind: Install
metadata:
  creationTimestamp: 2019-03-07T19:49:05Z
  generation: 1
  name: istio
  namespace: supergloo-system
  resourceVersion: "137866"
  selfLink: /apis/supergloo.solo.io/v1/namespaces/supergloo-system/installs/istio
  uid: 104e79ee-4112-11e9-b67e-bcb07306190b
spec:

   ## add the following line 
   disabled: true            
   ##

  installedManifest: ... # long gzipped string, should not be modified
  installedMesh:
      name: istio
      namespace: supergloo-system
    istio:
      enableAutoInject: true
      enableMtls: true
      installGrafana: true
      installJaeger: true
      installPrometheus: true
      installationNamespace: istio-system
      istioVersion: 1.0.6
```

Verify uninstallation has begun: 

```bash
kubectl get pod -n istio-system --watch

istio-system   istio-cleanup-secrets-xd6f8   0/1       Terminating   0         23m
istio-system   istio-cleanup-secrets-xd6f8   0/1       Terminating   0         23m
istio-system   istio-galley-6c68c5dbcf-z6j5k   1/1       Terminating   0         23m
istio-system   grafana-7f6cd4bf56-xst2n   1/1       Terminating   0         23m
istio-system   istio-policy-977d74ff4-669vk   2/2       Terminating   0         23m
istio-system   istio-telemetry-5f79796bf6-fl4sn   2/2       Terminating   0         23m
istio-system   istio-pilot-c5dddb4b9-nb6fd   2/2       Terminating   0         23m
istio-system   prometheus-76db5fddd5-55r6d   1/1       Terminating   0         23m
istio-system   istio-citadel-796c94878b-59gw6   1/1       Terminating   0         23m
istio-system   istio-sidecar-injector-6d8f88c98f-5f58t   1/1       Terminating   0         23m
istio-system   istio-tracing-7596597bd7-lc92t   1/1       Terminating   0         23m
istio-system   istio-policy-977d74ff4-669vk   0/2       Terminating   0         23m
istio-system   istio-policy-977d74ff4-669vk   0/2       Terminating   0         23m
istio-system   istio-galley-6c68c5dbcf-z6j5k   0/1       Terminating   0         23m
istio-system   grafana-7f6cd4bf56-xst2n   0/1       Terminating   0         23m
istio-system   istio-pilot-c5dddb4b9-nb6fd   0/2       Terminating   0         23m
istio-system   istio-pilot-c5dddb4b9-nb6fd   0/2       Terminating   0         23m
istio-system   istio-sidecar-injector-6d8f88c98f-5f58t   0/1       Terminating   0         23m
istio-system   istio-sidecar-injector-6d8f88c98f-5f58t   0/1       Terminating   0         23m
istio-system   istio-sidecar-injector-6d8f88c98f-5f58t   0/1       Terminating   0         23m
istio-system   istio-galley-6c68c5dbcf-z6j5k   0/1       Terminating   0         23m
istio-system   istio-galley-6c68c5dbcf-z6j5k   0/1       Terminating   0         23m
istio-system   istio-tracing-7596597bd7-lc92t   0/1       Terminating   0         23m
istio-system   istio-tracing-7596597bd7-lc92t   0/1       Terminating   0         23m
istio-system   istio-tracing-7596597bd7-lc92t   0/1       Terminating   0         23m
istio-system   istio-telemetry-5f79796bf6-fl4sn   0/2       Terminating   0         23m
istio-system   istio-telemetry-5f79796bf6-fl4sn   0/2       Terminating   0         23m
istio-system   istio-telemetry-5f79796bf6-fl4sn   0/2       Terminating   0         23m
istio-system   grafana-7f6cd4bf56-xst2n   0/1       Terminating   0         23m
istio-system   grafana-7f6cd4bf56-xst2n   0/1       Terminating   0         23m
istio-system   grafana-7f6cd4bf56-xst2n   0/1       Terminating   0         23m
istio-system   istio-policy-977d74ff4-669vk   0/2       Terminating   0         23m
istio-system   istio-policy-977d74ff4-669vk   0/2       Terminating   0         23m
istio-system   prometheus-76db5fddd5-55r6d   0/1       Terminating   0         23m
istio-system   prometheus-76db5fddd5-55r6d   0/1       Terminating   0         23m
istio-system   prometheus-76db5fddd5-55r6d   0/1       Terminating   0         23m
istio-system   istio-citadel-796c94878b-59gw6   0/1       Terminating   0         23m
istio-system   istio-citadel-796c94878b-59gw6   0/1       Terminating   0         23m
istio-system   istio-citadel-796c94878b-59gw6   0/1       Terminating   0         23m
istio-system   istio-pilot-c5dddb4b9-nb6fd   0/2       Terminating   0         23m
istio-system   istio-pilot-c5dddb4b9-nb6fd   0/2       Terminating   0         23m
istio-system   istio-pilot-c5dddb4b9-nb6fd   0/2       Terminating   0         23m
```

Note that the `istio-system` namespace will be left intact by this process, but can be safely removed using 
`kubectl delete ns istio-system`. 