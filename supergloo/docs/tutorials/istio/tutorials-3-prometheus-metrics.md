---
title: "Tutorial: Configuring Prometheus to Collect Istio Metrics"
menuTitle: Prometheus to Collect Istio Metrics
weight: 3
---

# Overview

In this tutorial we'll take a look at how to configure [the Prometheus monitoring system](https://prometheus.io/) to scrape our meshes for metrics using SuperGloo.

Monitoring the traffic being sent between a system of microservices is one of the primary features provided by service meshes. Service meshes make it easy to collect
metrics from a large, distributed system in a centralized metrics store such as Prometheus. Typically, when installing a mesh, the mesh and metrics store must be manually configured in order to produce readable metrics.

SuperGloo provides features to automatically propagate metrics from a managed mesh with one or more instances of a metrics store.

Let's dive right in.

# Tutorial

First, ensure you've:

- [installed SuperGloo]({{% ref "/installation" %}})
- [installed Istio using SuperGloo]({{% ref "/mesh/install-istio" %}})
- [Deployed the Bookinfo sample app]({{% ref "/tutorials/bookinfo" %}})

Next, we'll need an instance of Prometheus running in our cluster. If you've already got Prometheus installed, you can skip this step.

> Note: For SuperGloo to configure Prometheus correctly, it requires that the Prometheus server is configured with a
> [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/), and that the
> key for the Prometheus configuration file is named `prometheus.yml`

To install a simple Prometheus instance for the purpose of this tutorial, run the following:

```shell
kubectl create namespace prometheus-test
kubectl --namespace prometheus-test apply --filename \
    https://raw.githubusercontent.com/solo-io/solo-docs/master/supergloo/examples/prometheus/prometheus-demo.yaml
```

> Note: We can watch the pods get created for Prometheus with `kubectl --namespace prometheus-test get pod -w`

Let's take a look at the configmap that was created by this install for us:

```bash
kubectl --namespace prometheus-test get configmap
```

```noop
NAME                DATA      AGE
prometheus-server   3         5s
```

We'll need to pass the name `prometheus-test.prometheus-server` to SuperGloo as a configuration option for our mesh.

SuperGloo will append jobs to Prometheus' [scrape configuration](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config)
when it is connected to that instance's configmap. Run the following command to connect SuperGloo to the Prometheus instance we just installed:

```bash
supergloo set mesh stats \
    --target-mesh supergloo-system.istio-istio-system \
    --prometheus-configmap prometheus-test.prometheus-server
```

After a few seconds, we should be able to see that SuperGloo updated the Prometheus config with jobs telling it
to scrape Istio:

```bash
kubectl --namespace prometheus-test get configmap --output yaml | grep istio
```

```yaml
      - job_name: supergloo-istio-supergloo-system.istio-envoy-stats
      - job_name: supergloo-istio-supergloo-system.istio-galley
            - istio-system
          regex: istio-galley;http-monitoring
      - job_name: supergloo-istio-supergloo-system.istio-istio-mesh
            - istio-system
          regex: istio-telemetry;prometheus
      - job_name: supergloo-istio-supergloo-system.istio-istio-policy
            - istio-system
          regex: istio-policy;http-monitoring
      - job_name: supergloo-istio-supergloo-system.istio-istio-telemetry
            - istio-system
          regex: istio-telemetry;http-monitoring
      - job_name: supergloo-istio-supergloo-system.istio-pilot
            - istio-system
          regex: istio-pilot;http-monitoring
```

We can see the configuration that this applied to our Mesh CRD by running:

```bash
kubectl --namespace supergloo-system get mesh istio-istio-system --output yaml
```

{{< highlight yaml "hl_lines=14-17" >}}
apiVersion: supergloo.solo.io/v1
kind: Mesh
metadata:
  creationTimestamp: 2019-03-28T18:44:46Z
  generation: 1
  name: istio-istio-system
  namespace: supergloo-system
  resourceVersion: "178284"
  selfLink: /apis/supergloo.solo.io/v1/namespaces/supergloo-system/meshes/istio
  uid: 8f57f47e-5189-11e9-9c12-b0cb59a58200
spec:
  istio:
    installationNamespace: istio-system
  monitoringConfig:
    prometheusConfigmaps:
    - name: prometheus-server
      namespace: prometheus-test
  mtlsConfig:
    mtlsEnabled: true
status:
  reported_by: istio-config-reporter
  state: 1
{{< /highlight >}}

Notice how the `monitoringConfig` now contains an entry for our `prometheus-server` configmap.

Let's take a look at the metrics that our Prometheus instance should have started collecting for our mesh.

Open up a port-forward to reach the Prometheus UI from our local machine:

```shell
kubectl --namespace prometheus-test port-forward deployment/prometheus-server 9090
```

Now direct your browser to <http://localhost:9090/>

You should see the Prometheus Graph page show up:

![Prometheus Landing Page](/img/prometheus-landing-page.png "Prometheus Landing Page")

Let's enter a query to see some stats from Istio. We'll try `istio_requests_total`:

![Prometheus Initial Query](/img/prometheus-initial-query.png "Prometheus Initial Query")

Let's try creating some metrics by sending traffic to some of our Bookinfo pods. Open the port-forward to
reach the productpage:

```bash
kubectl --namespace default port-forward deployment/productpage-v1 9080
```

Open your browser to <http://localhost:9080/productpage>. Refresh the page a few times -
this will cause the product page to send requests to the reviews and ratings services.

Now let's check back in Prometheus and try the query `istio_requests_total{destination_app="reviews"}`
(note that it might take up to 30 seconds before new metrics are scraped by Prometheus):

![Prometheus Updated Query](/img/prometheus-updated-query.png "Prometheus Updated Query")

We can see that the number of requests sent to the reviews service (triggered by us refreshing the page)
correlates to the rise in the graph.

Great! We've just seen how SuperGloo makes it easier to connect an existing Prometheus installation
to a managed Mesh with a minimal amount of work.
