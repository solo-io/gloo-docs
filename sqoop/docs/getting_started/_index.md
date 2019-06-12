---
weight: 20
title: Getting Started
---

## Getting Started on Kubernetes

### What you'll need

- [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [`sqoopctl`](https://sqoop.solo.io)
- [`glooctl`](https://gloo.solo.io): (OPTIONAL) to see how Sqoop is interacting with the underlying system
- Kubernetes v1.8+ deployed somewhere. [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) is a great way to get a cluster up quickly.

This tutorial will install sqoop into the namespace `gloo-system` by default, this is configurable from the `sqoopctl` cli.

### Steps

#### Deploy Sqoop and Gloo

```shell
sqoopctl install kube
```

#### Deploy the Pet Store

```shell
kubectl --namespace default apply \
    -f https://raw.githubusercontent.com/solo-io/gloo/master/example/petstore/petstore.yaml
```

#### OPTIONAL: View the petstore functions using `glooctl`

Wait a minute for the petstore service to fully deploy and to be discovered by sqoop/gloo. Then you can run the
following command to see the REST functions that have been discovered.

```shell
glooctl get upstreams default-petstore-8080
```

```noop
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

The upstream we want to see is `default-petstore-8080`. The functions `addPet`, `deletePet`, `findPetById`, and `findPets`
will become the resolvers for our GraphQL schema.

##### Alternatively: find the upstreams using `kubectl`

```bash
kubectl --namespace gloo-system get upstreams
```

```noop
NAME                            AGE
default-kubernetes-443          7m45s
default-petstore-8080           7m45s
gloo-system-gateway-proxy-443   7m43s
gloo-system-gateway-proxy-80    7m43s
gloo-system-gloo-9977           7m44s
gloo-system-sqoop-9095          7m42s
kube-system-kube-dns-53         7m45s
kube-system-kube-dns-9153       7m45s
```

The upstream we are interested in is the petstore, so we run the following to find the functions:

```bash
kubectl --namespace gloo-system get upstreams default-petstore-8080 --output yaml
```

```yaml
apiVersion: gloo.solo.io/v1
kind: Upstream
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"labels":{"app":"petstore"},"name":"petstore","namespace":"default"},"spec":{"ports":[{"name":"http","port":8080,"protocol":"TCP","targetPort":8080}],"selector":{"app":"petstore"}}}
  creationTimestamp: "2019-06-12T16:00:39Z"
  generation: 4
  labels:
    app: petstore
    discovered_by: kubernetesplugin
  name: default-petstore-8080
  namespace: gloo-system
  resourceVersion: "708"
  selfLink: /apis/gloo.solo.io/v1/namespaces/gloo-system/upstreams/default-petstore-8080
  uid: 3934cec4-8d2b-11e9-b735-0242ac110002
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

#### Create a GraphQL Schema

An example schema is located in `petstore.graphql`

```graphql
# The query type, represents all of the entry points into our object graph
type Query {
    pets: [Pet]
    pet(id: Int!): Pet
}

type Mutation {
    addPet(pet: InputPet!): Pet
}

type Pet{
    id: ID!
    name: String!
}

input InputPet{
    id: ID!
    name: String!
    tag: String
}
```

#### Upload the Schema

Upload the schema to Sqoop using `sqoopctl`:

```bash
sqoopctl schema create petstore -f petstore.graphql
```

#### OPTIONAL: View the Generated Resolvers

A Sqoop [**ResolverMap**](../v1/github.com/solo-io/sqoop/api/v1/resolver_map.proto.sk) will have been generated
for the new schema.

Take a look at its structure:

```bash
kubectl --namespace gloo-system get resolvermaps --output yaml
```

```yaml
apiVersion: v1
items:
- apiVersion: sqoop.solo.io/v1
  kind: ResolverMap
  metadata:
    annotations:
      created_for: petstore
    creationTimestamp: "2019-06-12T16:19:22Z"
    generation: 2
    name: petstore
    namespace: gloo-system
    resourceVersion: "903"
    selfLink: /apis/sqoop.solo.io/v1/namespaces/gloo-system/resolvermaps/petstore
    uid: d684a62b-8d2d-11e9-a399-0242ac110002
  spec:
    types:
      Mutation:
        fields:
          addPet: {}
      Pet:
        fields:
          id: {}
          name: {}
      Query:
        fields:
          pet: {}
          pets: {}
  status:
    reported_by: sqoop
    state: 1
kind: List
metadata:
  resourceVersion: ""
  selfLink: ""
```

The empty `{}`'s are Sqoop [**Resolver**](../v1/github.com/solo-io/sqoop/api/v1/resolver_map.proto.sk)
objects, waiting to be filled in. Sqoop supports a variety of Resolver types (and supports extension to its
resolution system). In this tutorial, we will create Gloo resolvers, which allow you to connect schema fields
to REST APIs, serverless functions and other Gloo functions.

#### Register some Resolvers

Let's use `sqoopctl` to register some resolvers.

```bash
# register findPetById for Query.pets (specifying no arguments)
sqoopctl resolvermap register --upstream default-petstore-8080 --schema petstore --function findPets Query pets
# register a resolver for Query.pet
sqoopctl resolvermap register --upstream default-petstore-8080 --schema petstore --function findPetById Query pet
# register a resolver for Mutation.addPet
# the request template tells Sqoop to use the Variable "pet" as an argument
sqoopctl resolvermap register --upstream default-petstore-8080 --schema petstore --function addPet Mutation addPet --request-template '{{ marshal (index .Args "pet") }}'
```

That's it! Now we should have a functioning GraphQL frontend for our REST service.

#### Visit the Playground

Visit the exposed address of the `sqoop` service in your browser.

If you're running in minkube, you can get this address with the command

```bash
echo http://$(minikube ip):$(kubectl --namespace gloo-system get service sqoop --output 'jsonpath={.spec.ports[?(@.name=="http")].nodePort}')

http://192.168.39.47:30935/
```

You can also use the following `port-forward` and the Sqoop GraphQL playground will be at <http://localhost:9095>

```shell
kubectl --namespace gloo-system port-forward service/sqoop 9095:9095
```

You should see a landing page for Sqoop which contains a link to the GraphQL Playground for our
Pet Store. Visit it and try out some queries!

examples:

```graphql
{
  pet(id:1 ) {
    name
  }
}
```

&darr;

```json
{
  "data": {
    "pet": {
      "name": "Dog"
    }
  }
}
```

```graphql
{
  pets {
    name
  }
}
```

&darr;

```json
{
  "data": {
    "pets": [
      {
        "name": "Dog"
      },
      {
        "name": "Cat"
      }
    ]
  }
}
```

```graphql
mutation($pet: InputPet!) {
  addPet(pet: $pet) {
    id
    name
  }
}
```

with input variable

```json
{
  "pet":{
    "id":3,
    "name": "monkey"
  }
}
```

&darr;

```json
{
  "data": {
    "addPet": {
      "name": "monkey"
    }
  }
}
```
