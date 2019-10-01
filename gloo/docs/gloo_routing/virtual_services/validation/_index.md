---
menuTitle: Config Validation
title: Enabling Configuration Validation -
weight: 10
description: >
 (Kubernetes Only) Gloo can be configured to validate configuration before it is applied to the cluster.
 With validation enabled, any attempt to apply invalid configuration to the cluster will be rejected.
---

Gloo runs a [Kubernetes Validating Admission Webhook](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)
which is invoked whenever a `gateway.solo.io` custom resource is created or modified. This includes 
[Gateways]({{< ref "/api/github.com/solo-io/gloo/projects/gateway/api/v2/gateway.proto.sk.md">}}), 
[Virtual Services]({{< ref "/api/github.com/solo-io/gloo/projects/gateway/api/v1/virtual_service.proto.sk.md">}}),
and [Route Tables]({{< ref "/api/github.com/solo-io/gloo/projects/gateway/api/v1/route_table.proto.sk.md">}}).
 
By default, the Validation Webhook only logs the validation result, but always admits resources regardless of validation errors.

The webhook can be configured to reject invalid resources via the 
[Settings]({{< ref "/api/github.com/solo-io/gloo/projects/gloo/api/v1/settings.proto.sk.md">}}) resource.

If using Helm to manage settings, set the following value:

```bash
--set gateway.validation.alwaysAcceptResources=false
```

If writing Settings directly to Kubernetes, add the following to the `spec.gateway` block:

{{< highlight yaml "hl_lines=13-15" >}}
apiVersion: gloo.solo.io/v1
kind: Settings
metadata:
  annotations:
    helm.sh/hook: pre-install
    helm.sh/hook-weight: "5"
  labels:
    app: gloo
  name: default
  namespace: gloo-system
spec:
  discoveryNamespace: gloo-system
  gateway:
    validation:
      alwaysAccept: false
  gloo:
    xdsBindAddr: 0.0.0.0:9977
  kubernetesArtifactSource: {}
  kubernetesConfigSource: {}
  kubernetesSecretSource: {}
  refreshRate: 60s
{{< /highlight >}}

Once these are applied to the cluster, we can test that validation is enabled:


```bash
kubectl apply -f - <<EOF
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: reject-me
  namespace: default
spec:
  virtualHost:
    routes:
      # this route is missing a path specifier and will be rejected
      - matcher: {}
        routeAction:
          single:
            upstream:
              name: does-not-exist
              namespace: anywhere
EOF

```

We should see the request was rejected:

```bash
Error from server: error when creating "STDIN": admission webhook "gateway.gloo-system.svc" denied the request: resource incompatible with current Gloo snapshot: [Route Error: InvalidMatcherError. Reason: no path specifier provided]
```

More options for configuring the validation webhook can be found in the
 [Settings documentation]({{< ref "/api/github.com/solo-io/gloo/projects/gloo/api/v1/settings.proto.sk.md">}}).


Please submit questions and feedback to [the solo.io slack channel](https://slack.solo.io/), or [open an issue on GitHub](https://github.com/solo-io/gloo).


