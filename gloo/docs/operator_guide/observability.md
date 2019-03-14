---
title: Observability
weight: 3
---


All gloo pods ship with optional [prometheus](https://prometheus.io/) monitoring as well as [open tracing](https://opentracing.io/) capability.

This functionality is turned off by default but can be turned on a couple of different ways.

The first way is via the helm chart. All deployment objects in the helm templates accept an argument `stats` which
when set to true, start a stats server on the given pod. for example: 
```yaml
gloo:
  deployment:
    image:
      repository: quay.io/solo-io/gloo
      pullPolicy: Always
    xdsPort: 9977
    replicas: 1
    stats: true
```
This flag will set the `START_STATS_SERVER` env variable to true in the container which will start the stats server on port 9091.

The other method is to manually set the `START_STATS_SERVER=1` in the pod. 

### Monitoring Gloo with Prometheus

Prometheus has great support for monitoring kubermetes pods. Docs for that can be found [here](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config).
If the stats are enabled through the helm chart than the prometheus annotations are automatically added to the pod spec.

### Open Tracimg

Open tracing stats are also available from the admin page in our pods.

### Enterprise features

The enterprise version of Gloo ships with full obersvability setup from the get go with prometheus and grafana configrued, and watching.
GlooE also makes all envoy stats readily available via the included deployment, or an existing one


