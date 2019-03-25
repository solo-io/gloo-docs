---
title: Basic Path Routing
weight: 10
description: Basic routing example for using Gloo to route requests based on query path.
---

## Path Routing

API Gateways can route incoming traffic to backend services. Gloo can automatically discover backend services based on
plugins that it uses that know intimate details about the platform or environment on which it's running. In this
tutorial we look at Gloo's basic upstream discovery and routing capabilities. For more advanced *function* routing,
take a look at the [function routing](../function_routing) tutorial.

{{% notice note %}}
If a gateway has no routes, Gloo will not listen on the gateway's port.
{{% /notice %}}

### What you'll need

* [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* Kubernetes v1.11.3+ deployed somewhere. [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) is a
great way to get a cluster up quickly.

### Steps

1. The Gloo Gateway [installed]({{< ref "/installation" >}}) and running on Kubernetes.

1. Next, deploy the Pet Store app to kubernetes:

    ```shell
    kubectl apply \
      --filename https://raw.githubusercontent.com/solo-io/gloo/master/example/petstore/petstore.yaml
    ```

1. The discovery services should have already created an Upstream for the petstore service.
Let's verify this:

    ```shell
    glooctl get upstreams
    ```

    ```noop
    +--------------------------------+------------+----------+------------------------------+
    |            UPSTREAM            |    TYPE    |  STATUS  |           DETAILS            |
    +--------------------------------+------------+----------+------------------------------+
    | default-kubernetes-443         | Kubernetes | Pending  | svc name:      kubernetes    |
    |                                |            |          | svc namespace: default       |
    |                                |            |          | port:          8443          |
    |                                |            |          |                              |
    | default-petstore-8080          | Kubernetes | Accepted | svc name:      petstore      |
    |                                |            |          | svc namespace: default       |
    |                                |            |          | port:          8080          |
    |                                |            |          | REST service:                |
    |                                |            |          | functions:                   |
    |                                |            |          | - addPet                     |
    |                                |            |          | - deletePet                  |
    |                                |            |          | - findPetById                |
    |                                |            |          | - findPets                   |
    |                                |            |          |                              |
    | gloo-system-gateway-proxy-8080 | Kubernetes | Accepted | svc name:      gateway-proxy |
    |                                |            |          | svc namespace: gloo-system   |
    |                                |            |          | port:          8080          |
    |                                |            |          |                              |
    | gloo-system-gloo-9977          | Kubernetes | Accepted | svc name:      gloo          |
    |                                |            |          | svc namespace: gloo-system   |
    |                                |            |          | port:          9977          |
    |                                |            |          |                              |
    +--------------------------------+------------+----------+------------------------------+
    ```

    The upstream we want to see is `default-petstore-8080`. Digging a little deeper,
    we can verify that Gloo's function discovery populated our upstream with
    the available rest endpoints it implements. Note: the upstream was created in
    the `gloo-system` namespace rather than `default` because it was created by a
    discovery service. Upstreams and virtualservices do not need to live in the `gloo-system`
    namespace to be processed by Gloo.

1. Let's take a closer look at the functions that are available on this upstream:

    ```shell
    glooctl get upstream default-petstore-8080 --output yaml
    ```

    ```yaml
    ---
    discoveryMetadata: {}
    metadata:
      annotations:
        kubectl.kubernetes.io/last-applied-configuration: |
          {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"labels":{"service":"petstore"},"name":"petstore","namespace":"default"},"spec":{"ports":[{"port":8080,"protocol":"TCP"}],"selector":{"app":"petstore"}}}
      labels:
        discovered_by: kubernetesplugin
        service: petstore
      name: default-petstore-8080
      namespace: gloo-system
      resourceVersion: "268143"
    status:
      reportedBy: gloo
      state: Accepted
    upstreamSpec:
      kube:
        selector:
          app: petstore
        serviceName: petstore
        serviceNamespace: default
        servicePort: 8080
        serviceSpec:
          rest:
            swaggerInfo:
              url: http://petstore.default.svc.cluster.local:8080/swagger.json
            transformations:
              addPet:
                body:
                  text: '{"id": {{ default(id, "") }},"name": "{{ default(name, "")}}","tag":
                    "{{ default(tag, "")}}"}'
                headers:
                  :method:
                    text: POST
                  :path:
                    text: /api/pets
                  content-type:
                    text: application/json
              deletePet:
                headers:
                  :method:
                    text: DELETE
                  :path:
                    text: /api/pets/{{ default(id, "") }}
                  content-type:
                    text: application/json
              findPetById:
                body: {}
                headers:
                  :method:
                    text: GET
                  :path:
                    text: /api/pets/{{ default(id, "") }}
                  content-length:
                    text: "0"
                  content-type: {}
                  transfer-encoding: {}
              findPets:
                body: {}
                headers:
                  :method:
                    text: GET
                  :path:
                    text: /api/pets?tags={{default(tags, "")}}&limit={{default(limit,
                      "")}}
                  content-length:
                    text: "0"
                  content-type: {}
                  transfer-encoding: {}
    ```

    The details of this application were discovered by Gloo's Function Discovery (fds) service. Because the petstore
    application implements OpenAPI (specifically discovering a Swagger JSON document on `petstore-svc/swagger.json`).
    Because some functions were discovered for us, we can practice some function in the next tutorial.

1. Let's now use `glooctl` to create a basic route for this upstream.

    ```shell
    glooctl add route \
        --path-exact /sample-route-1 \
        --dest-name default-petstore-8080 \
        --prefix-rewrite /api/pets
    ```

    We use the `--prefix-rewrite` to rewrite path on incoming requests
    to match the paths our petstore expects.

    Note that we have omitted the `--name` flag for selecting a virtual service. Routes are always associated
    with a Virtual Service in Gloo, which groups routes by their domain. Since we skipped creating a
    virtual service for this route, `my-virtual-service` will be created automatically for us.

    With `glooctl`, we can see that a virtual service was created with our route:

    ```shell
    glooctl get virtualservice --output yaml
    ```

    {{< highlight yaml >}}
---
metadata:
  name: default
  namespace: gloo-system
  resourceVersion: "268264"
status:
  reportedBy: gateway
  state: Accepted
  subresourceStatuses:
    '*v1.Proxy gloo-system gateway-proxy':
      reportedBy: gloo
      state: Accepted
virtualHost:
  domains:
  - '*'
  name: gloo-system.default
  routes:
  - matcher:
      exact: /sample-route-1
    routeAction:
      single:
        upstream:
          name: default-petstore-8080
          namespace: gloo-system
    routePlugins:
      prefixRewrite:
        prefixRewrite: /api/pets
    {{< /highlight >}}

    Note that you can add routes interactively using `glooctl add route -i`. This is a great way
    to explore Gloo's configuration options from the CLI.

1. Let's test the route `/sample-route-1` using `curl`:

    ```shell
    export GATEWAY_URL=$(glooctl proxy url)
    curl ${GATEWAY_URL}/sample-route-1
    ```

    ```json
    [{"id":1,"name":"Dog","status":"available"},{"id":2,"name":"Cat","status":"pending"}]
    ```

Great! our gateway is up and running. Let's make things a bit more sophisticated in the next section with
[Function Routing](../function_routing).
