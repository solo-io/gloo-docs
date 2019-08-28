---
title: Open Policy Agent Authorization
weight: 30
description: Illustrating how to combine OpenID Connect with Open Policy Agent to achieve fine grained policy with Gloo.
---

## Motivation

Open Policy Agent (OPA for short) can be used to express versatile organization policies.
Starting of gloo-e version 0.18.20 you can used OPA policies to make authorization decisions
on incoming requests.
This allows you having uniform policy language all across your organization.
This also allows you to create more fine grained policies compared to RBAC authorization system. For more information, see [here](https://www.openpolicyagent.org/docs/latest/comparison-to-other-systems/).

##  Prerequisites

- A Kubernetes cluster. [minikube](https://github.com/kubernetes/minikube) is a good way to get started
- `glooctl` - To install and interact with Gloo (optional).

## Install Gloo and Test Service

That's easy!

```
glooctl install gateway --license-key=$GLOO_KEY
kubectl --namespace default apply -f https://raw.githubusercontent.com/solo-io/gloo/master/example/petstore/petstore.yaml
```

See more information and options of installing Gloo [here](/installation/enterprise).

### Verify Install
Make sure all is deployed correctly:

```shell
curl $(glooctl proxy url)/api/pets
```

should respond with
```json
[{"id":1,"name":"Dog","status":"available"},{"id":2,"name":"Cat","status":"pending"}]
```

## Configuring an Open Policy Agent Policy 

Open Policy Agent policies are written in Rego. The Rego language is inspired from Datalog, which inturn is a subset of Prolog. Rego is more suited to work with modern JSON documents.

### Create the Policy 
Let's create a Policy to control what actions are allowed on our service, and apply it to Kubernetes as a ConfigMap:

```shell
cat <<EOF > /tmp/policy.rego
package test

default allow = false
allow {
    startswith(input.http_request.path, "/api/pets")
    input.http_request.method == "GET"
}
allow {
    input.http_request.path == "/api/pets/2"
    any({input.http_request.method == "GET",
        input.http_request.method == "DELETE"
    })
}
EOF
kubectl --namespace=gloo-system create configmap allow-get-users --from-file=/tmp/policy.rego
```

Let's break this down:

- This policy denies everything by default
- It is allowed if:
  - The path starts with "/api/pets" AND the http method is "GET"
  - OR
  - The path is exactly "/api/pets/2" AND the http method is either "GET" or "DELETE"

In the next setup, we will attach this policy to a Gloo VirtualService to enforce it.


### Create a VirtualService with the OPA Authorization

To enforce the policy, we will create a Gloo VirtualService with OPA Authorization enabled. We will refer to the policy created above, and add a query that allows access
only if the `allow` variable is `true`:

{{< tabs >}}
{{< tab name="kubectl" codelang="yaml">}}
kind: VirtualService
metadata:
  name: default
  namespace: gloo-system
spec:
  displayName: default
  virtualHost:
    domains:
    - '*'
    routes:
    - matcher:
        prefix: /
      routeAction:
        single:
          upstream:
            name: default-petstore-8080
            namespace: gloo-system
    virtualHostPlugins:
      extensions:
        configs:
          extauth:
            configs:
            - opa_auth:
                modules:
                - name: allow-get-users
                  namespace: gloo-system
                query: "data.test.allow == true"
{{< /tab >}}
{{< tab name="glooctl" codelang="shell">}}
glooctl create vs --name default --enable-opa-auth --opa-query 'data.test.allow == true' --opa-module-ref gloo-system.allow-get-users
glooctl add route --name default --path-prefix / --dest-name default-petstore-8080 --dest-namespace gloo-system
{{< /tab >}}
{{< /tabs >}} 

That's all that is needed as far as configuration. Let's verify that all is working as expected.

## Verify

```shell
URL=$(glooctl proxy url)
```

Paths that don't start with /api/pets are not authorized (should return 403):
```
curl -s -w "%{http_code}\n" $URL/api/

403
```

Not allowed to delete pets/1  (should return 403):
```
curl -s -w "%{http_code}\n" $URL/api/pets/1 -X DELETE

403
```

Allowed to delete pets/2  (should return 204):
```
curl -s -w "%{http_code}\n" $URL/api/pets/2 -X DELETE

204
```


# Open Policy Agent and Open ID Connect

We can use OPA to verify policies on the JWT coming from Gloo's OpenID Connect authentication.

Let's first configure an OpenID Connect provider on your cluster.
similar to dex doc - install dex 