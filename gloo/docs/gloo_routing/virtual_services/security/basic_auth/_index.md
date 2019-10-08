---
title: Basic Auth
weight: 10
description: Authenticating using a dictionary of usernames and passwords on a virtual service. 
---

{{% notice note %}}
{{< readfile file="static/content/enterprise_only_feature_disclaimer" markdown="true">}}
{{% /notice %}}

In certain cases - such as during testing or when releasing a new API to a small number of known users - it may be 
convenient to secure a Virtual Service using [**Basic Authentication**](https://en.wikipedia.org/wiki/Basic_access_authentication). 
With this simple authentication mechanism the encoded user credentials are sent along with the request in a standard header.

To secure your Virtual Services using Basic Authentication, you first need to provide Gloo with a set of known users and 
their passwords. You can then use this information to decide who is allowed to access which routes.
If a request matches a route on which Basic Authentication is configured, Gloo will verify the credentials in the 
standard `Authorization` header before sending the request to its destination. If the user associated with the credentials 
is not explicitly allowed to access that route, Gloo will return a 401 response to the downstream client.

Be sure to check the external auth [configuration overview]({{< ref "gloo_routing/virtual_services/security#configuration-overview" >}}) 
for detailed information about how authentication is configured on Virtual Services.

## Setup
{{< readfile file="/static/content/setup_notes" markdown="true">}}

Let's start by creating a [Static Upstream]({{< ref "gloo_routing/virtual_services/routes/route_destinations/single_upstreams/static_upstream" >}}) 
that routes to a website; we will send requests to it during this tutorial.

{{< tabs >}}
{{< tab name="kubectl" codelang="yaml">}}
{{< readfile file="/static/content/upstream.yaml">}}
{{< /tab >}}
{{< tab name="glooctl" codelang="shell" >}}
glooctl create upstream static --static-hosts jsonplaceholder.typicode.com:80 --name json-upstream
{{< /tab >}}
{{< /tabs >}}

## Creating a Virtual Service
Now let's configure Gloo to route requests to the upstream we just created. To do that, we define a simple Virtual 
Service to match all requests that:

- contain a `Host` header with value `foo` and
- have a path that starts with `/` (this will match all requests).

{{< tabs >}}
{{< tab name="kubectl" codelang="yaml">}}
{{< readfile file="gloo_routing/virtual_services/security/basic_auth/test-no-auth-vs.yaml">}}
{{< /tab >}}
{{< tab name="glooctl" codelang="shell">}}
glooctl create vs --name test-no-auth --namespace gloo-system --domains foo
glooctl add route --name test-no-auth --path-prefix / --dest-name json-upstream
{{< /tab >}}
{{< /tabs >}} 

Let's send a request that matches the above route to the Gloo Gateway and make sure it works:

```shell
curl -H "Host: foo" $GATEWAY_URL/posts/1
```

The above command should produce the following output:

```json
{
  "userId": 1,
  "id": 1,
  "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
  "body": "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto"
}
```

## Securing the Virtual Service
{{% notice warning %}}
{{< readfile file="/static/content/extauth_version_info_note" >}}
{{% /notice %}}

As we just saw, we were able to reach the upstream without having to provide any credentials. This is because by default 
Gloo allows any request on routes that do not specify authentication configuration. Let's change this behavior. 
We will update the Virtual Service so that only requests by the user `user` with password `password` are allowed.
Gloo expects password to be hashed and [salted](https://en.wikipedia.org/wiki/Salt_(cryptography)) using the
[APR1](https://httpd.apache.org/docs/2.4/misc/password_encryptions.html) format. Passwords in this format follow this pattern:

> $apr1$**SALT**$**HASHED_PASSWORD**

To generate such a password you can use the `htpasswd` utility:

```shell
htpasswd -nbm user password
```

Running the above command returns a string like `user:$apr1$TYiryv0/$8BvzLUO9IfGPGGsPnAgSu1`, where:

- `TYiryv0/` is the salt and
- `8BvzLUO9IfGPGGsPnAgSu1` is the hashed password.

Now that we have a password in the required format, let's go ahead and create and `AuthConfig` CRD with our 
Basic Authentication configuration:

{{< highlight shell "hl_lines=13-14" >}}
kubectl apply -f - <<EOF
apiVersion: enterprise.gloo.solo.io/v1
kind: AuthConfig
metadata:
  name: basic-auth
  namespace: gloo-system
spec:
  configs:
  - basicAuth:
      apr:
        users:
          user:
            salt: "TYiryv0/"
            hashedPassword: "8BvzLUO9IfGPGGsPnAgSu1"
EOF
{{< /highlight >}}

Once the `AuthConfig` has been created, we can use it to secure our Virtual Service:

{{< highlight shell "hl_lines=19-23" >}}
kubectl apply -f - <<EOF
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: auth-tutorial
  namespace: gloo-system
spec:
  virtualHost:
    domains:
      - 'foo'
    routes:
      - matcher:
          prefix: /
        routeAction:
          single:
            upstream:
              name: json-upstream
              namespace: gloo-system
    virtualHostPlugins:
      extauth:
        config_ref:
          name: basic-auth
          namespace: gloo-system
EOF
{{< /highlight >}}

In the above example we have added the configuration to the Virtual Host. Each route belonging to a Virtual Host will 
inherit its `AuthConfig`, unless it [overwrites or disables]({{< ref "gloo_routing/virtual_services/security#inheritance-rules" >}}) it.

### Testing denied requests
Let's try and resend the same request we sent earlier:

```shell
curl -v -H "Host: foo" $GATEWAY_URL/posts/1
```

You will see that the response now contains a **401 Unauthorized** code, indicating that Gloo denied the request.

{{< highlight shell "hl_lines=6" >}}
> GET /posts/1 HTTP/1.1
> Host: foo
> User-Agent: curl/7.54.0
> Accept: */*
>
< HTTP/1.1 401 Unauthorized
< www-authenticate: Basic realm=""
< date: Mon, 07 Oct 2019 13:36:58 GMT
< server: envoy
< content-length: 0
{{< /highlight >}}

### Testing authenticated requests
For a request to be allowed, it must now include the user credentials inside the expected header, which has the 
following format:

```
Authorization: basic <base64_encoded_credentials>
```

To encode the credentials, just run:

```shell
echo -n "user:password" | base64
```

This outputs `dXNlcjpwYXNzd29yZA==`. Let's include the header with this value in our request:

```shell
curl -H "Authorization: basic dXNlcjpwYXNzd29yZA==" -H "Host: foo" $GATEWAY_URL/posts/1
```

We are now able to reach the upstream again!

```json
{
  "userId": 1,
  "id": 1,
  "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
  "body": "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto"
}
```

## Summary

In this tutorial, we installed Gloo Enterprise and created an unauthenticated Virtual Service that routes requests to a 
static upstream. We then created a Basic Authentication `AuthConfig` object and used it to secure our Virtual Service. 
We first showed how unauthenticated requests fail with a `401 Unauthorized` response, and then showed how to send 
authenticated requests successfully to the upstream. 

Cleanup the resources by running:

```
kubectl delete ac -n gloo-system basic-auth
kubectl delete vs -n gloo-system auth-tutorial
kubectl delete upstream -n gloo-system json-upstream
```
