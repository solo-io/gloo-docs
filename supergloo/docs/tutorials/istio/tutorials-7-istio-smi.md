---
title: "Configuring Istio using the SMI Spec"
weight: 51
description: "Enable Service Mesh Interface (SMI) Configuration of Istio using SuperGloo."

---

## Motivation

The [Service Mesh Interface](https://github.com/deislabs/smi-spec) (SMI) provides a standard API specification 
to make it possible for applications that leverage service mesh APIs to code for a consistent API regardless of the underlying mesh. 

SuperGloo can translate user configuration to SMI language, enabling integration with other tools and services built on top of the SMI spec.

For example, when using the [SMI Istio Adapter](https://github.com/deislabs/smi-adapter-istio) with [SuperGloo TrafficShifting Rules]({{% ref "/tutorials/istio/tutorials-1-trafficshifting" %}}) SuperGloo will generate [SMI TrafficSplits](https://github.com/deislabs/smi-spec/blob/master/traffic-split.md) instead of [Istio VirtualServices](https://istio.io/docs/reference/config/networking/v1alpha3/virtual-service). The SMI Adapter handles the final translation to Istio Virtual Services, allowing multiple SMI-integrated extensions to work-side-by-side with SuperGloo to manage the underlying mesh.

This tutorial will present a modified version of the [SuperGloo traffic shifting tutorial]({{% ref "/tutorials/istio/tutorials-1-trafficshifting" %}}) using the SMI translation in place of the Istio API.

### Setup

First, make sure you've [installed SuperGloo to your cluster]({{% ref "/installation" %}}).

Next, we'll deploy Istio *with the SMI adapter enabled*:

```bash
supergloo install istio --name istio --installation-namespace istio-system --mtls=true --auto-inject=true --smi-install
```

> Note: If you've already installed Istio to your cluster using SuperGloo, add the `--update` flag to this command


Once Istio is installed, we should see that the SMI adapter is deployed with it:

```bash
kubectl get pod -n istio-system
```

{{< highlight yaml "hl_lines=12" >}}
NAME                                     READY   STATUS      RESTARTS   AGE
istio-citadel-5bbbc98c6d-s8b99           1/1     Running     0          6d1h
istio-cleanup-secrets-qbwq9              0/1     Completed   0          6d1h
istio-galley-744969c89-7jjlx             1/1     Running     0          6d1h
istio-pilot-5b5b66b495-jb6mw             2/2     Running     0          6d1h
istio-policy-7b8f874df6-84swc            2/2     Running     0          6d1h
istio-security-post-install-9ktgl        0/1     Completed   0          6d1h
istio-sidecar-injector-856b74c95-26jt7   1/1     Running     0          6d1h
istio-telemetry-868d55d686-j4gvl         2/2     Running     0          6d1h
istio-telemetry-868d55d686-t278r         2/2     Running     0          2m33s
istio-telemetry-868d55d686-xfptf         2/2     Running     0          30h
smi-adapter-istio-f564fbcd8-xlchp        1/1     Running     0          2m53s
{{< /highlight >}}

We can verify that SuperGloo's `meshdiscovery` service has detected that SMI has been enabled for istio:

```bash
kubectl get mesh -n supergloo-system istio-istio-system -o yaml
```

{{< highlight yaml "hl_lines=29" >}}
apiVersion: supergloo.solo.io/v1
kind: Mesh
metadata:
  creationTimestamp: "2019-05-15T12:18:07Z"
  generation: 1
  labels:
    created_by: mesh-discovery
    discovered_by: istio-mesh-discovery
  name: istio-istio-system
  namespace: supergloo-system
  resourceVersion: "6968896"
  selfLink: /apis/supergloo.solo.io/v1/namespaces/supergloo-system/meshes/my-istio
  uid: 7f6bf1f9-770b-11e9-ae6d-42010a800047
spec:
  discoveryMetadata:
    enableAutoInject: true
    injectedNamespaceLabel: istio-injection
    installationNamespace: istio-system
    meshVersion: 1.0.6
    mtlsConfig:
      mtlsEnabled: true
    upstreams:
    ...
  istio:
    installationNamespace: istio-system
    version: 1.0.6
  mtlsConfig:
    mtlsEnabled: true
  smiEnabled: true
status:
  reported_by: istio-config-reporter
  state: 1

{{< /highlight >}}

## Configuring the Adapter

Now that the adapter has been installed and detected, let's begin configuring it with SuperGloo.

To demonstrate the SMI TrafficSplit feature, we'll follow the same steps from the Traffic Shifting tutorial.

First, make sure the [bookinfo app is installed]({{% ref "/tutorials/bookinfo" %}}).

Now let's the Product Page UI In our browser with the help of `kubectl port-forward`. Run the following
command in another terminal window or the background:

```shell
kubectl port-forward -n default deployment/productpage-v1 9080
```

Open your browser to <http://localhost:9080/productpage>. When you refresh the page,
you should see that the representation of stars below the Book Reviews alternates between
being black, red, and not showing at all. This is because, by default, traffic is
being shifted between `v1/v2/v3` of the `reviews` service.

Now let's create a configuration that allows us to force all traffic to `v3` of our service. As the SMI spec 
does not support routing to a subset of pods for a service, 
we will need to create another kubernetes Service that maps 
to the `v3` subset of pods:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: reviewsv3
  namespace: default
  labels:
    app: reviews
    version: v3
spec:
  ports:
    - port: 9080
      name: http
  selector:
    app: reviews
    version: v3
EOF
```

Once that's done, we'll use the `supergloo` CLI to create a routing rule.

Run the following command to configure a traffic shifting rule:

```shell
supergloo apply routingrule trafficshifting \
    --name reviews-v3 \
    --dest-upstreams supergloo-system.default-reviews-9080 \
    --target-mesh supergloo-system.istio \
    --destination supergloo-system.default-reviewsv3-9080:1
```

We can view the routing rule this created with `kubectl get routingrule --namespace supergloo-system reviews-v3 --output yaml`:

```yaml
apiVersion: supergloo.solo.io/v1
kind: RoutingRule
metadata:
  name: reviews-v3
  namespace: supergloo-system
  resourceVersion: "22111"
spec:
  destinationSelector:
    upstreamSelector:
      upstreams:
      - name: default-reviews-9080
        namespace: supergloo-system
  spec:
    trafficShifting:
      destinations:
        destinations:
        - destination:
            upstream:
              name: default-reviewsv3-9080
              namespace: supergloo-system
          weight: 1
  targetMesh:
    name: istio
    namespace: supergloo-system
status:
  reported_by: istio-config-reporter
  state: 1
```

> Note: RoutingRules can be managed entirely using YAML files and `kubectl`. The CLI provides commands for generating SuperGloo CRD YAML, understanding the state of the system, and debugging.

This rule tells SuperGloo to take all traffic bound for the upstream `default-reviews-9080` and route 100% of it to `default-reviewsv3-9080`. The `default-reviews-9080` upstream represents the whole set of pods for the `default.reviews` service, while `default-reviewsv3-9080` represents the subset of those pods with the label `version: v3`.

Try refreshing the page at http://localhost:9080/productpage. 
We should see that only the red-stars version of the app appears.

Let's verify that SuperGloo is configuring the SMI Adapter directly by running some commands to print CRDs:

```bash
kubectl  get trafficsplits.split.smi-spec.io --all-namespaces -o yaml
```
```
apiVersion: v1
items:
- apiVersion: split.smi-spec.io/v1alpha1
  kind: TrafficSplit
  metadata:
    creationTimestamp: "2019-05-21T15:50:53Z"
    generation: 2
    labels:
      created_by: smi-config-syncer
    name: reviews-v3-reviews.default.svc.cluster.local
    namespace: supergloo-system
    resourceVersion: "5334084"
    selfLink: /apis/split.smi-spec.io/v1alpha1/namespaces/supergloo-system/trafficsplits/reviews-v3-reviews.default.svc.cluster.local
    uid: 36951aa0-7be0-11e9-81a4-42010a800052
  spec:
    backends:
    - service: reviewsv3.default.svc.cluster.local
      weight: "1"
    service: reviews.default.svc.cluster.local
```

Using this feature, you can integrate other SMI-supported mesh extensions alongside SuperGloo, while leveraging SuperGloo's 
ease of use, multi-mesh API, and operational features.
