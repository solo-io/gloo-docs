---
title: Plugin Auth
weight: 40
description: Extend Gloo's built-in auth server with custom Go plugins
---

We have seen that one way of implementing custom authentication logic is by 
[providing your own auth server]({{< ref "gloo_routing/virtual_services/authentication/custom_auth/_index.md" >}}). 
While this approach gives you great freedom, it also comes at a cost: 

- you have to write and manage an additional service; 
- if your authentication logic is very simple, the plumbing needed to get it running might constitute a significant overhead;
- if your auth server serves only as an adapter for an existing auth service, it will introduce an additional 
network hop with the associated latency to any request that needs to be authenticated; that, or you will need to update 
your existing service so that it can accept the requests Gloo sends it;
- you likely want to be able to define specific configuration for your auth server, e.g. based on which virtual 
host is serving the request. This is feasible, but requires the configuration to live outside of Gloo, which makes it 
harder to kept it in sync with your virtual services and negates the benefits of a centralized control plane.

Wouldn't it be nice to be able to **write just the authentication logic you need, plug it into Gloo, and be able to 
provide your specific configuration** right on the Virtual Services it applies to? Starting with **Gloo Enterprise**, 
release 0.18.11+, you can do just that! 

In this guide we will show you how easy it is to extend Gloo's Ext Auth server via [Go plugins](https://golang.org/pkg/plugin/).

## Development workflow overview
Following are the high-level steps required to use your plugin with Gloo. In the following sections we will see 
each one of them in greater detail.

1. Write a plugin and publish it as a `docker image` which, when run, copies the compiled plugin file to a 
predefined directory.
2. Configure Gloo to load the plugin by running the image as an `initContainer` on the `extauth` deployment. This can be 
done by rendering the Gloo Helm chart with some value overrides or by modifying the Gloo installation manifest manually.
3. Reference your plugin in your Virtual Services for it to be invoked for requests matching particular virtual hosts or 
routes.

TODO(marco): fill in specific link
{{% notice note %}}
For a more in-depth explanation of the Ext Auth Plugin development workflow, please check our dedicated s
[Developer Guide]({{< ref "dev/_index.md" >}}).
{{% /notice %}}

## Building an Ext Auth plugin

{{% notice note %}}
The code used in this section can be found [in our ext-auth-plugins GitHub repository](https://github.com/solo-io/ext-auth-plugins).
{{% /notice %}}

The [official Go docs](https://golang.org/pkg/plugin/) describe a plugin as:

>> "*a Go main package with exported functions and variables that has been built with: `go build -buildmode=plugin`*"

In order for Gloo to be able to load your plugin, the `main` package of your plugin must export a variable that 
implements the [ExtAuthPlugin](https://github.com/solo-io/ext-auth-plugins/blob/master/api/interface.go) interface 
(check the source code for a detailed explanation of the two functions):

```go
type ExtAuthPlugin interface {
	NewConfigInstance(ctx context.Context) (configInstance interface{}, err error)
	GetAuthService(ctx context.Context, configInstance interface{}) (AuthService, error)
}
```


For this guide we will use a simple example plugin that has already been built. You can find the source code to build it 
yourself [here](https://github.com/solo-io/ext-auth-plugins/tree/master/examples/required_header).

The plugin authorizes requests if:
 
- they contain a certain header
- the value for the header is in a predefined whitelist

The `main` package for the plugin looks like this:

{{< highlight go "hl_lines=10-11" >}}
package main

import (
	"github.com/solo-io/ext-auth-plugins/api"
	impl "github.com/solo-io/ext-auth-plugins/examples/required_header/pkg"
)

func main() {}

// This is the exported variable that Gloo will look for. It implements the ExtAuthPlugin interface.
var Plugin impl.RequiredHeaderPlugin
{{< /highlight >}}

We leave it up to you to inspect the simple `impl.RequiredHeaderPlugin` object. Of interest here is the following 
configuration object it defines:

```go
type Config struct {
	RequiredHeader string
	AllowedValues  []string
}
```

The values in this struct will determine the aforementioned header and whitelist.

#### Packaging and publishing the plugin
Ext Auth plugins must be made available to Gloo in the form of container images. The images must contain the compiled 
plugins and copy these files to the `/auth-plugins` when run. 

In this guide we will use the image for the `RequiredHeaderPlugin` introduced above. It has been built using 
[this Dockerfile](https://github.com/solo-io/ext-auth-plugins/blob/master/Dockerfile) and can be found in 
the `quay.io/solo-io/ext-auth-plugins` docker repository. Let's inspect the image:

{{< highlight shell_script "hl_lines=3" >}}
docker run -it --entrypoint ls quay.io/solo-io/ext-auth-plugins:0.0.1 -l compiled-auth-plugins
total 55636
-rw-r--r--    1 root     root      28958552 Aug 13 19:37 RequiredHeader.so
{{< /highlight >}}

You can see that it contains the compiled plugin file `RequiredHeader.so`.

## Configuring Gloo

#### Installation
Let's start by installing Gloo Enterprise (make sure the version is >= **0.18.11**). We will use the 
[Helm install option]({{< ref "installation/enterprise#installing-on-kubernetes-with-helm" >}}), as it is the easiest 
way of configuring Gloo to load your plugin. First we need to fetch the Helm chart:

```bash
helm fetch glooe/gloo-ee --version "0.18.12"
```

Then we have to create the following `plugin-values.yaml` value overrides file:

{{< highlight bash "hl_lines=7-12" >}}
cat << EOF > plugin-values.yaml
license_key: YOUR_LICENSE_KEY
global:
  extensions:
    extAuth:
      plugins:
        my-plugin:
          image:
            repository: ext-auth-plugins
            registry: quay.io/solo-io
            pullPolicy: Always
            tag: 0.0.1
EOF
{{< /highlight >}}

`global.extensions.extAuth.plugins` is a map where:

* each key is a plugin container display name (in this case `my-plugin`)
* the correspondent value is an image spec

Now we can render the helm chart and `apply` it:

{{< highlight bash "hl_lines=7-12" >}}
helm template gloo-ee --name glooe --namespace gloo-system -f plugin-values.yaml | kubectl apply -f -
{{< /highlight >}}

If we inspect the `extauth` deployment by running

```bash
kubectl get deployment -n gloo-system extauth -o yaml
```

we should see the following information (non relevant attributes have been omitted):

{{< highlight yaml "hl_lines=23-36" >}}
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: gloo
    gloo: extauth
  name: extauth
  namespace: gloo-system
spec:
  selector:
    matchLabels:
      gloo: extauth
  template:
    metadata:
      labels:
        gloo: extauth
    spec:
      containers:
      - image: quay.io/solo-io/extauth-ee:0.18.12
        imagePullPolicy: Always
        name: extauth
        resources: {}
        volumeMounts:
        - mountPath: /auth-plugins
          name: auth-plugins
      initContainers:
      - image: quay.io/solo-io/ext-auth-plugins:0.0.1
        imagePullPolicy: Always
        name: plugin-my-plugin
        resources: {}
        volumeMounts:
        - mountPath: /auth-plugins
          name: auth-plugins
      volumes:
      - emptyDir: {}
        name: auth-plugins
{{< /highlight >}}

Each plugin container image built as described in the 
[*Packaging and publishing the plugin* section]({{< ref "gloo_routing/virtual_services/authentication/plugin_auth#packaging-and-publishing-the-plugin" >}}) 
has been added as an `initContainer` to the `extauth` deployment. A volume named `auth-plugins` is mounted in the 
`initContainer`s and the `extauth` container at `/auth-plugins` path: when the `initContainer`s are run, they will copy 
the compiled plugin files they contain (in this case `RequiredHeader.so`) to the shared volume, where they become available 
to the `extauth` server.

Let's verify that the `extauth` server did successfully start by checking its logs.

```bash
kc logs -n gloo-system deployment/extauth
{"level":"info","ts":1566305605.7575822,"logger":"extauth","caller":"runner/run.go:78","msg":"Starting ext-auth server"}
{"level":"info","ts":1566305605.7587602,"logger":"extauth","caller":"runner/run.go:93","msg":"extauth server running in grpc mode, listening at :8083"}
```

#### Create a simple Virtual Service
To test our auth plugin, we first need to create an upstream. Let's start by creating a simple service that will return 
"Hello World" when receiving HTTP requests:

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: http-echo
  name: http-echo
spec:
  selector:
    matchLabels:
      app: http-echo
  replicas: 1
  template:
    metadata:
      labels:
        app: http-echo
    spec:
      containers:
      - image: hashicorp/http-echo:latest
        name: http-echo
        args: ["-text='Hello World!'"]
        ports:
        - containerPort: 5678
          name: http
---
apiVersion: v1
kind: Service
metadata:
  name: http-echo
  labels:
    service: http-echo
spec:
  ports:
  - port: 5678
    protocol: TCP
  selector:
    app: http-echo
EOF
```

Now we can create a virtual service that will route any requests with the `/echo` prefix to the `echo` service.

{{< tabs >}}
{{< tab name="yaml" codelang="yaml">}}
{{< readfile file="gloo_routing/virtual_services/authentication/plugin_auth/vs-echo-no-auth.yaml">}}
{{< /tab >}}
{{< tab name="glooctl" codelang="shell">}}
glooctl create vs --name http-echo --namespace gloo-system
glooctl add route --path-prefix /echo --dest-name default-http-echo-5678
{{< /tab >}}
{{< /tabs >}} 

To verify that the Virtual Service works, let's get the URL of the Gloo Gateway and send a request to `/echo`:

```bash
export GATEWAY_URL=$(glooctl proxy url)
```

```bash
curl $GATEWAY_URL/echo
'Hello World!'
```

#### Secure the Virtual Service
Gloo will not perform any authentication for the route we just defined. To configure Gloo to authenticate the requests 
served by the virtual host that the route belongs to, we need to add the following to the Virtual Service definition:

{{< highlight yaml "hl_lines=20-34" >}}
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: echo
  namespace: gloo-system
spec:
  displayName: echo
  virtualHost:
    domains:
    - '*'
    name: gloo-system.echo
    routes:
    - matcher:
        prefix: /echo
      routeAction:
        single:
          upstream:
            name: default-http-echo-5678
            namespace: gloo-system
    virtualHostPlugins:
      extensions:
        configs:
          extauth:
            plugin_auth:
              plugins:
              - config:
                  RequiredHeader: my-header
                  AllowedValues:
                  - foo
                  - bar
                  - baz
                name: RequiredHeader
                plugin_file_name: RequiredHeader.so
                exported_symbol_name: Plugin
{{< /highlight >}}

This configures the virtual host to authenticate requests using the `plugin_auth` mode. `plugins` is an array of plugins 
(in Gloo terms a **plugin chain**), where each element has the following structure:

- `name`: the name of the plugin. This serves mainly for display purposes, but is also used to build the default values 
for the next two fields.
- `plugin_file_name`: the name of the compiled plugin that was copied to the `/auth-plugins` directory. Defaults to `<name>.so`.
- `exported_symbol_name`: the name of the exported symbol Gloo will look for when loading the plugin. Defaults to `<name>`.
- `config`: information that will be used to configure your plugin. Gloo will attempt to parse the value of this 
attribute into the object pointer returned by your plugin's `NewConfigInstance` function implementation. In our case 
this will be an instance of `*Config`, as seen in the 
[*Building an Ext Auth plugin* section]({{< ref "gloo_routing/virtual_services/authentication/plugin_auth#building-an-ext-auth-plugin" >}}).

{{% notice note %}}
Plugins in a **plugin chain** will be executed in the order they are defined. The first plugin to deny the request will 
cause the chain execution to be interrupted. The headers on each plugin response will be merged into the request to the 
next one. Check the [Developer Guide]({{< ref "dev/_index.md" >}}) for more information about how the headers are merged.
{{% /notice %}}

After `apply`-ing this Virtual Service, let's check the `extauth` logs again:

{{< highlight yaml "hl_lines=4-6" >}}
kc logs -n gloo-system deployment/extauth
{"level":"info","ts":1566316248.9934704,"logger":"extauth","caller":"runner/run.go:78","msg":"Starting ext-auth server"}
{"level":"info","ts":1566316248.9935324,"logger":"extauth","caller":"runner/run.go:93","msg":"extauth server running in grpc mode, listening at :8083"}
{"level":"info","ts":1566316249.0016804,"logger":"extauth","caller":"runner/run.go:150","msg":"got new config","config":[{"vhost":"gloo-system.gateway-proxy-v2-listener-::-8080-gloo-system_echo","AuthConfig":{"PluginAuth":{"plugins":[{"name":"RequiredHeader","plugin_file_name":"RequiredHeader.so","exported_symbol_name":"Plugin","config":{"fields":{"AllowedValues":{"Kind":{"ListValue":{"values":[{"Kind":{"StringValue":"foo"}},{"Kind":{"StringValue":"bar"}},{"Kind":{"StringValue":"baz"}}]}}},"RequiredHeader":{"Kind":{"StringValue":"my-header"}}}}}]}}}]}
{"level":"info","ts":1566316249.0287502,"logger":"extauth.header_value_plugin","caller":"pkg/impl.go:38","msg":"Parsed RequiredHeaderAuthService config","requiredHeader":"my-header","allowedHeaderValues":["foo","bar","baz"]}
{"level":"info","ts":1566316249.0289364,"logger":"extauth","caller":"plugins/loader.go:85","msg":"Successfully loaded plugin. Adding it to the plugin chain.","pluginName":"RequiredHeader"}
{{< /highlight >}}

From the last three lines we can see that the Ext Auth server received the new configuration for our virtual service. 
If we try to hit our route again, we should see a `403` response:

```bash
curl -v $GATEWAY_URL/echo
*   Trying 192.168.99.100...
* TCP_NODELAY set
* Connected to 192.168.99.100 (192.168.99.100) port 30519 (#0)
> GET /echo HTTP/1.1
> Host: 192.168.99.100:30519
> User-Agent: curl/7.54.0
> Accept: */*
>
< HTTP/1.1 403 Forbidden
< date: Tue, 20 Aug 2019 15:01:57 GMT
< server: envoy
< content-length: 0
<
* Connection #0 to host 192.168.99.100 left intact
```

If you recall the structure of our plugin, it will only allow request with a given header (in this case `my-header`) and 
where that header has an expected value (in this case one of `foo`, `bar` or `baz`). If we include a header with these 
properties in our request, we will be able to hit our `echo` service:

{{< highlight bash "hl_lines=20" >}}
curl -v -H "my-header: foo" $GATEWAY_URL/echo
*   Trying 192.168.99.100...
* TCP_NODELAY set
* Connected to 192.168.99.100 (192.168.99.100) port 30519 (#0)
> GET /echo HTTP/1.1
> Host: 192.168.99.100:30519
> User-Agent: curl/7.54.0
> Accept: */*
> my-header: foo
>
< HTTP/1.1 200 OK
< x-app-name: http-echo
< x-app-version: 0.2.3
< date: Tue, 20 Aug 2019 16:02:12 GMT
< content-length: 15
< content-type: text/plain; charset=utf-8
< x-envoy-upstream-service-time: 0
< server: envoy
<
'Hello World!'
* Connection #0 to host 192.168.99.100 left intact
{{< /highlight >}}

## Summary
In this guide we installed Enterprise Gloo and configured it to load a sample Go plugin that implements custom 
auth logic. Then we created a simple virtual service to route requests to a test upstream. Finally, we updated the 
virtual service to use our plugin and saw how requests are allowed or denied based on the custom configuration for our 
plugin.

You can cleanup the resources created while following this guide by running:
```bash
glooctl uninstall -n gloo-system
```

## Next steps
As a next step, check out our [Developer Guide]({{< ref "dev/_index.md" >}}) for a detailed tutorial on how to build your own Ext Auth plugins!
