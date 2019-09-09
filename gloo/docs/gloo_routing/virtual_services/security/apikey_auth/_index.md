---
title: ApiKey Auth
weight: 40
description: How to setup ApiKey authentication. 
---

There are a few different ways to use Gloo External Auth. In certain cases – such as protecting routes with
secure, long-lived UUIDs – it may be desirable to secure a set of routes with **ApiKey Auth**. Keep in mind
that your routes are only as secure as your apikeys; securing apikeys and proper apikey rotation is
up to the user, thus the security of the routes is up to the user.

In **ApiKey Auth**, the Gloo VirtualService containing the routes can be configured with a label selector to identify
multiple valid apikey secrets, or direct references to apikey secrets. When the virtual service configuration changes,
or when any apikey secret changes, Gloo immediately updates the external auth server with the new configuration. On the
request path, Envoy asks the external auth service to check the request; any request to a path on that virtual
service must have a valid apikey in the `api-key` header or will be denied.

## Setup

{{% notice note %}}
ApiKey auth is a feature of **Gloo Enterprise**, release 0.18.5+. If you are using Open Source Gloo, this tutorial will not work.
{{% /notice %}}


{{< readfile file="/static/content/setup_notes" markdown="true">}}

Let's create a simple upstream for testing called `json-upstream`, that routes to a static site:

{{< tabs >}}
{{< tab name="kubectl" codelang="yaml">}}
{{< readfile file="/static/content/upstream.yaml">}}
{{< /tab >}}
{{< tab name="glooctl" codelang="shell" >}}
glooctl create upstream static --static-hosts jsonplaceholder.typicode.com:80 --name json-upstream
{{< /tab >}}
{{< /tabs >}}

## Creating a virtual service

First, let's create a virtual service with no auth configured. 

{{< tabs >}}
{{< tab name="kubectl" codelang="yaml">}}
{{< readfile file="gloo_routing/virtual_services/security/apikey_auth/test-no-auth-vs.yaml">}}
{{< /tab >}}
{{< tab name="glooctl" codelang="shell">}}
glooctl create vs --name test-no-auth --namespace gloo-system --domains foo
glooctl add route --name test-no-auth --path-prefix / --dest-name json-upstream
{{< /tab >}}
{{< /tabs >}} 

Let's make a request to that route and make sure it works:

```shell
curl -H "Host: foo" $GATEWAY_URL/posts/1
```

returns

```json
{
  "userId": 1,
  "id": 1,
  "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
  "body": "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto"
}
```

## Creating an authenticated virtual service

Now let's create a virtual service that routes the same upstream, but with apikey authentication. First, let's create
an apikey secret that's part of the `infrastructure` team with `N2YwMDIxZTEtNGUzNS1jNzgzLTRkYjAtYjE2YzRkZGVmNjcy` as
the apikey.

```shell
glooctl create secret apikey infra-apikey --apikey N2YwMDIxZTEtNGUzNS1jNzgzLTRkYjAtYjE2YzRkZGVmNjcy --apikey-labels team=infrastructure
```

This creates a secret named `infra-apikey` in the `gloo-system` namespace. If we had instead opted to generate the apikey
using the `--apikey-generate` flag, we can extract the generated apikey by getting the secret contents and decoding the
extension configuration:

```shell
kubectl get secret infra-apikey -n gloo-system -oyaml
```

returns secret yaml similar to:

```yaml
apiVersion: v1
data:
  extension: Y29uZmlnOgogIGFwaV9rZXk6IE4yWXdNREl4WlRFdE5HVXpOUzFqTnpnekxUUmtZakF0WWpFMll6UmtaR1ZtTmpjeQogIGxhYmVsczoKICAtIHRlYW09aW5mcmFzdHJ1Y3R1cmUK
kind: Secret
metadata:
  annotations:
    resource_kind: '*v1.Secret'
  creationTimestamp: "2019-08-08T15:32:05Z"
  labels:
    team: infrastructure
  name: infra-apikey
  namespace: gloo-system
  resourceVersion: "2888983"
  selfLink: /api/v1/namespaces/gloo-system/secrets/infra-apikey
  uid: acfe796e-b9f1-11e9-a8d7-42010a800055
type: Opaque
```

Take the extension configuration and decode it to get the apikey:
```shell
echo Y29uZmlnOgogIGFwaV9rZXk6IE4yWXdNREl4WlRFdE5HVXpOUzFqTnpnekxUUmtZakF0WWpFMll6UmtaR1ZtTmpjeQogIGxhYmVsczoKICAtIHRlYW09aW5mcmFzdHJ1Y3R1cmUK | base64 -D
```

returns

```yaml
config:
  api_key: N2YwMDIxZTEtNGUzNS1jNzgzLTRkYjAtYjE2YzRkZGVmNjcy
  labels:
  - team=infrastructure
```

Our apikey is indeed `N2YwMDIxZTEtNGUzNS1jNzgzLTRkYjAtYjE2YzRkZGVmNjcy`! Now we can construct our virtual service
to allow access from all apikeys in the `infrastructure` team to our upstream:

{{< tabs >}}
{{< tab name="kubectl" codelang="yaml">}}
{{< readfile file="gloo_routing/virtual_services/security/apikey_auth/test-auth-vs.yaml">}}
{{< /tab >}}
{{< tab name="glooctl" codelang="shell">}}
glooctl create vs test-auth --domains bar --enable-apikey-auth --apikey-label-selector team=infrastructure
glooctl add route --name test-auth  --path-prefix / --dest-name json-upstream{{< /tab >}}
{{< /tabs >}} 


### Testing denied requests

Let's make a request to that route without auth and see that we get a 401 unauthorized response:

```shell
curl -v -H "Host: bar" $GATEWAY_URL/posts/1
```

The response will contain this:

```shell
< HTTP/1.1 401 Unauthorized
```

### Testing authenticated requests

For a request to be authenticated with apikey auth, it must include the `api-key` header that looks like this:
`api-key: TOKEN`, where `TOKEN` is the apikey:

Now let's add the authorization headers:

```shell
curl -H "api-key: N2YwMDIxZTEtNGUzNS1jNzgzLTRkYjAtYjE2YzRkZGVmNjcy" -H "Host: bar" $GATEWAY_URL/posts/1
```

returns

```json
{
  "userId": 1,
  "id": 1,
  "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
  "body": "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto"
}
```

## Summary

In this tutorial, we installed Enterprise Gloo and created a static upstream. Then we created an unauthenticated 
virtual service and saw requests get routed to it. Finally, we created a virtual service authenticated with 
apikey auth, and first showed how unauthenticated requests fail with a 401 Unauthorized response, and then showed how 
to send authenticated requests successfully to the route. 

Cleanup the resources by running:

{{< tabs >}}
{{< tab name="kubectl" codelang="yaml">}}
kubectl delete vs -n gloo-system test-no-auth
kubectl delete vs -n gloo-system test-auth
kubectl delete upstream -n gloo-system json-upstream
kubectl delete secret -n gloo-system infra-apikey
{{< /tab >}}
{{< tab name="glooctl" codelang="shell" >}}
glooctl delete vs test-no-auth
glooctl delete vs test-auth
glooctl delete upstream json-upstream
kubectl delete secret -n gloo-system infra-apikey
{{< /tab >}}
{{< /tabs >}}

<br /> 
<br /> 
