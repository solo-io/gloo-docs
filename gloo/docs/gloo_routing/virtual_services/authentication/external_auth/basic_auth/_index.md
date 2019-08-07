---
title: Basic Auth
weight: 1
description: Authenticating using a dictionary of usernames and passwords on a virtual service. 
---

There are a few different ways to use Gloo External Auth. In certain cases -- such as during testing, or when releasing 
a new API to a small number of known users -- it may be desirable to secure a set of routes with **Basic Auth**. 

In **BasicAuth**, the Gloo **VirtualService** containing the routes can be configured with a dictionary of 
authenticated usernames and password. When the virtual service configuration changes, Gloo immediately updates the 
external auth server with the new configuration. On the request path, Envoy asks the external auth service to check 
the request; any request to a path on that virtual service must have a valid set of credentials or will be denied. 

## Setup

{{% notice note %}}
Basic auth is a feature of **Gloo Enterprise**. If you are using Open Source Gloo, this tutorial will not work. 
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
{{< readfile file="gloo_routing/virtual_services/authentication/external_auth/basic_auth/test-no-auth-vs.yaml">}}
{{< /tab >}}
{{< tab name="glooctl" codelang="shell">}}
glooctl create vs --name test-post --namespace gloo-system --domains foo
glooctl add route --name test-post  --path-prefix / --dest-name json-upstream
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

Now let's create a virtual service that routes the same upstream, but with authentication for the user `user` with 
password `password`. First, let's created a salted and hashed password:

```shell
htpasswd -nbm user password
```

This returns a string like: `user:$apr1$TYiryv0/$8BvzLUO9IfGPGGsPnAgSu1`. From this string, we can extract the 
salt `TYiryv0/` and hashed password `8BvzLUO9IfGPGGsPnAgSu1`, and now we can construct our virtual service. 

{{< tabs >}}
{{< tab name="kubectl" codelang="yaml">}}
{{< readfile file="gloo_routing/virtual_services/authentication/external_auth/basic_auth/test-auth-vs.yaml">}}
{{< /tab >}}
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

For a request to be authenticated with basic auth, it must include the `Authorization` header that looks like this:
`Authorization: basic TOKEN`, where `TOKEN` is the base64-encoded user password:

```shell
echo -n "user:password" | base64
```

This outputs `dXNlcjpwYXNzd29yZA==`. Now let's add the authorization headers:

```shell
curl -H "Authorization: basic dXNlcjpwYXNzd29yZA==" -H "Host: bar" $GATEWAY_URL/posts/1
```

This returns the following response:

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
basic auth, and first showed how unauthenticated requests fail with a 401 Unauthorized response, and then showed how 
to send authenticated requests successfully to the route. 

Cleanup the resources by running:

{{< tabs >}}
{{< tab name="kubectl" codelang="yaml">}}
kubectl delete vs -n gloo-system test-no-auth
kubectl delete vs -n gloo-system test-auth
kubectl delete upstream -n gloo-system json-upstream
{{< /tab >}}
{{< tab name="glooctl" codelang="shell" >}}
glooctl delete vs test-no-auth
glooctl delete vs test-auth
glooctl delete upstream json-upstream
{{< /tab >}}
{{< /tabs >}}

<br /> 
<br /> 
