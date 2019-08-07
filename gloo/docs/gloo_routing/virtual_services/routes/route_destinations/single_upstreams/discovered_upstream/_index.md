---
title: Discovered Upstreams
weight: 20
description: Configure Gloo to route to a single upstream that was automatically detected by Gloo's built in discovery system.
---

Let's configure Gloo to route to a single upstream that was automatically detected by Gloo's built in discovery system. 
In this case, we'll deploy an application to Kubernetes and discovery will create a new `Upstream` CRD for the service
that was created. We'll then configure a virtual service to route to that upstream. 

{{< readfile file="/static/content/setup_notes" markdown="true">}}

## Deploy Petstore

Let's deploy a simple example application called `petstore`:

{{< tabs >}}
{{< tab name="kubectl" codelang="yaml">}}
kubectl apply \
      --filename https://raw.githubusercontent.com/solo-io/gloo/master/example/petstore/petstore.yaml
{{< /tab >}}
{{< /tabs >}}

This should deploy the petstore service to the default namespace. Gloo's discovery system is watching that namespace 
and should immediately create an upstream for the petstore service.  

## Look at discovered Upstream

Let's verify the service was discovered and an upstream was written. Discovery automatically creates a name based on 
the name and namespace of the service, and the port.  

We can do this using `glooctl`: 

```shell
glooctl get upstream -n gloo-system default-petstore-8080 -oyaml
```

```shell
+-----------------------+------------+----------+-------------------------+
|       UPSTREAM        |    TYPE    |  STATUS  |         DETAILS         |
+-----------------------+------------+----------+-------------------------+
| default-petstore-8080 | Kubernetes | Accepted | svc name:      petstore |
|                       |            |          | svc namespace: default  |
|                       |            |          | port:          8080     |
|                       |            |          | REST service:           |
|                       |            |          | functions:              |
|                       |            |          | - addPet                |
|                       |            |          | - deletePet             |
|                       |            |          | - findPetById           |
|                       |            |          | - findPets              |
|                       |            |          |                         |
+-----------------------+------------+----------+-------------------------+
```

Here, we can see an upstream was created and accepted. The upstream points to the petstore service on port 8080 in the
default namespace. In fact, Gloo discovered that it was a REST service and, using it's function discovery system, 
added the functions it found in the Swagger definition to the upstream.

Let's look at the yaml output for this upstream from Kubernetes:

```shell
kubectl get upstream -n gloo-system default-petstore-8080 -oyaml
```

```yaml
apiVersion: gloo.solo.io/v1
kind: Upstream
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"labels":{"service":"petstore"},"name":"petstore","namespace":"default"},"spec":{"ports":[{"port":8080,"protocol":"TCP"}],"selector":{"app":"petstore"}}}
  creationTimestamp: 2019-07-30T20:04:14Z
  generation: 4
  labels:
    discovered_by: kubernetesplugin
    service: petstore
  name: default-petstore-8080
  namespace: gloo-system
  resourceVersion: "360256"
  selfLink: /apis/gloo.solo.io/v1/namespaces/gloo-system/upstreams/default-petstore-8080
  uid: 344a9166-b305-11e9-bbf8-42010a800130
spec:
  discoveryMetadata: {}
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
status:
  reported_by: gloo
  state: 1
```

## Create a route to this service

Let's create a virtual service, and add a route that directs requests to a function on the petstore service. 
Specifically, we'll add a route for the path `/api/pets`. 

{{< tabs >}}
{{< tab name="kubectl" codelang="yaml">}}
{{< readfile file="gloo_routing/virtual_services/routes/route_destinations/single_upstreams/discovered_upstream/virtual-service.yaml">}}
{{< /tab >}}
{{< tab name="glooctl" codelang="shell">}}
glooctl create vs --name test-petstore --namespace gloo-system --domains foo 
glooctl add route --name test-petstore --path-prefix /api/pets --dest-name default-petstore-8080
{{< /tab >}}
{{< /tabs >}}

## Test the route

We can now query this route using curl. 

```shell
curl -H "Host: foo" $GATEWAY_URL/api/pets
```

This should return: 

```json
[{"id":1,"name":"Dog","status":"available"},{"id":2,"name":"Cat","status":"pending"}]
```

## Summary

We deployed an application to Kubernetes and Gloo automatically discovered upstreams from it, including specific 
functions off of a swagger definition. We created a virtual service and routed requests to one of those endpoints. 

Let's clean up the virtual service we created: 

{{< tabs >}}
{{< tab name="kubectl" codelang="yaml">}}
kubectl delete vs -n gloo-system test-petstore
{{< /tab >}}
{{< tab name="glooctl" codelang="shell" >}}
glooctl delete vs test-petstore
{{< /tab >}}
{{< /tabs >}}

<br />
<br />