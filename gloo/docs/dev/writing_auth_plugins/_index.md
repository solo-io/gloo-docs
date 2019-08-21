---
title: "Building custom auth plugins"
weight: 7
description: Guidelines and best practices for developing and configuring Go plugins to extend Gloo's ext auth server
---

## Intro
In the [**Plugin Auth** guide]({{< ref "gloo_routing/virtual_services/authentication/plugin_auth" >}}) we showed how 
easy it is to extend Gloo with custom authentication logic using Go plugins. That guide uses a 
[plugin](https://github.com/solo-io/ext-auth-plugin-examples/tree/master/plugins/required_header) that has already been 
built and published, and primarily focuses on giving an overview of the plugin development flow.

In this guide, we will get our hands dirty and dig into the nitty-gritty details of how to write, test, build, and 
publish your ext auth plugins.

#### Before you start
This guide will make frequent references to the code contained in our 
[Ext Auth Plugin examples](https://github.com/solo-io/ext-auth-plugin-examples) GitHub repository. In addition to sample 
plugin implementation, the repository contains useful tools to verify whether your plugin is compatible with a certain 
version of Gloo. Given the (TODO: ref) constrains imposed by Go plugins, these utilities will make your life 
significantly easier.

{{% notice note %}}
We recommend that you fork the example repository and use it as a starting point to develop your plugins.
{{% /notice %}}

#### Development workflow overview
In the [**Plugin Auth** guide]({{< ref "gloo_routing/virtual_services/authentication/plugin_auth#development-workflow-overview" >}}) 
we gave a high-level description of the steps required to use your plugin to extend Gloo:

1. Write a plugin and publish it as a `docker image` which, when run, copies the compiled plugin file to a 
predefined directory.
2. Configure Gloo to load the plugin by running the image as an `initContainer` on the `extauth` deployment. This can be 
done by rendering the Gloo Helm chart with some value overrides or by modifying the Gloo installation manifest manually.
3. Reference your plugin in your Virtual Services for it to be invoked for requests matching particular virtual hosts or 
routes.

In the following sections we will see each one of them in greater detail.

## Building and publishing and auth plugin
In this section we will see how to develop an auth plugin and distribute it in the format in which it can be consumed 
by Gloo.

### API overview
There are two interfaces that are of interest when developing external auth plugins. They are both defined 
[here](https://github.com/solo-io/ext-auth-plugins/blob/master/api/interface.go)

##### ExtAuthPlugin
Gloo expects auth plugins to implement the 
[ExtAuthPlugin](https://github.com/solo-io/ext-auth-plugins/blob/master/api/interface.go#L41) interface.

```go
type ExtAuthPlugin interface {
	NewConfigInstance(ctx context.Context) (configInstance interface{}, err error)
	GetAuthService(ctx context.Context, configInstance interface{}) (AuthService, error)
}
```

Objects that implement this interface are used as factories for authentication service instances. After Gloo detects a 
reference to your plugin on a Virtual Service and loads it, it will call the `NewConfigInstance` function to get an 
object to deserialize the plugin configuration into. 

{{% notice warning %}}
The object returned by the `NewConfigInstance` function **MUST** be a pointer type.
{{% /notice %}}

Let's see example to understand this better. If your plugin configuration looks like this:

{{< highlight yaml "hl_lines=17-22" >}}
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  name: test-auth
  namespace: gloo-system
spec:
  virtualHost:
    domains: {} # omitted for brevity
    routes: {} # omitted for brevity
    virtualHostPlugins:
      extensions:
        configs:
          extauth:
            plugin_auth:
              plugins:
              - name: my-plugin
                plugin_file_name: MyPlugin.so
                exported_symbol_name: Plugin
                config:
                  some_key: value-1
                  some_struct:
                    another_key: value-2
{{< /highlight >}}

then `NewConfigInstance` function of your `ExtAuthPlugin` implementation should return a pointer to the following Go struct:

```go
type MyPluginConfig struct {
    SomeKey string
    SomeStruct NestedConfig
}

type NestedConfig struct {
    AnotherKey string
 }
```

Gloo will populate the struct fields with the values found on the correspondent YAML attributes.

{{% notice note %}}
You might have noticed that the `plugins` attribute in the configuration example above is an array. It is in fact 
possible to define multiple plugins on a virtual host. We'll see how [plugin chains](TODO) work later on.
{{% /notice %}}

The `GetAuthService` function will be invoked by Gloo right after this step. As its `configInstance` argument, Gloo will 
pass the object that it just populated with the values from the plugin configuration. This function must return an 
instance of the [AuthService](https://github.com/solo-io/ext-auth-plugins/blob/master/api/interface.go#L29) interface.

##### AuthService
`AuthService` instances are responsible for authorizing individual requests. This is the interface that all of Gloo's 
out-of-the box auth implementations (basic auth, OIDC, etc.) implement as well. Your plugin is responsible for providing 
Gloo with a valid `AuthService` implementation.

```go
type AuthService interface {
	Start(ctx context.Context) error
	Authorize(ctx context.Context, request *envoyauthv2.CheckRequest) (*AuthorizationResponse, error)
}
```

The `Start` function will be called once by Gloo, when the auth service is started. It is intended as a hook to perform 
initialization logic or to start auxiliary processes that span the whole lifecycle of the service.

All the functions we have just described will be invoked when Gloo detects a new auth configuration on your Virtual 
Services. The `Authorize` function will be invoked when a request hits Gloo and matches the virtual host on which the 
your plugin is defined. The `AuthorizationResponse` that it returns will determine whether the request will be allowed 
or denied. We provide minimal responses of both types via the `AuthorizedResponse()` and `UnauthorizedResponse()` 
functions in [the same package](https://github.com/solo-io/ext-auth-plugins/blob/master/api/interface.go#L95). You can 
use them as a basis for your own responses.

#### About the AuthService lifecycle
We mentioned how `ExtAuthPlugin` implementations function as factories for `AuthService` instances. It's worth spending 
a few words on the lifecycle of `AuthService`s. You might have noticed that Gloo passes a `context.Context` to each of 
the functions we just saw. The context will live as long as the plugin configuration that generated it is valid. 
Whenever the auth configuration changes, Gloo will start new `AuthService` instances and signal the termination of the 
previous one by cancelling the context it provided to them.

Following is the sequence of actions that Gloo performs when it detects a change in the overall auth configuration. 
Let's assume we start with a blank sheet, that is, no plugins are configured on any of your Virtual Services.

1. Start a new cancellable `context.Context`
2. Loop over all detected plugin configurations and for each one:
    1. Load the correspondent plugin `.so` file from the `auth-plugins` directory (more info about this later TODO)
    2. Invoke `NewConfigInstance` **passing in the context**
    3. Deserialize detected plugin config into the provided object
    4. Invoke `GetAuthService` **passing in the context** and the configuration object
    5. (if more than one plugin) Add it to the plugin chain TODO ref
3. If an error occurred, return it and do not update the `extauth` server configuration, else continue
4. Cancel the previous `context.Context`
5. Invoke the `Start` functions on all plugins **passing in the context**
6. Apply the plugin configurations to the `extauth` server

We recommend that you tie all the goroutines that you may spawn to the provided context by watching its `Done` channel. 
This will prevent your plugin from leaking memory. You can find a great overview of `Context` and how to best use it 
in [this Go Blog post](https://blog.golang.org/context).\

#### How to make your plugin implement `ExtAuthPlugin`
Earlier in this guide we mentioned that Gloo expects auth plugins to implement the 
[ExtAuthPlugin](https://github.com/solo-io/ext-auth-plugins/blob/master/api/interface.go#L41) interface. To understand 
what we mean by that, let's take a closer look at how Go plugins work.

The [official Go docs](https://golang.org/pkg/plugin/) describe a plugin as:

>> "*a Go main package with exported functions and variables that has been built with: `go build -buildmode=plugin`*"

In order for Gloo to be able to load your plugin, the `main` package of your plugin must export a variable that 
implements the [ExtAuthPlugin](https://github.com/solo-io/ext-auth-plugins/blob/master/api/interface.go) interface. 
This is usually a struct or a pointer to a struct (Gloo is smart enough to handle both cases). 
Gloo will use the [Lookup function](https://golang.org/pkg/plugin/#Plugin.Lookup) to find the exported variable and 
assert that it in fact implements the expected interface.

You can specify the name of the variable Gloo looks for when you reference your plugin in your virtual services:

{{< highlight yaml "hl_lines=5" >}}
plugin_auth:
  plugins:
  - name: my-plugin
    plugin_file_name: MyPlugin.so
    exported_symbol_name: Plugin
    config: {}
{{< /highlight >}}

We will get back to this configuration [later](TODO).

### Build helper tools
Now that we saw how to write your plugin, it's time to look at how to build it. When working with plugins, building your 
code is not as straightforward as when working with regular Go programs. Go plugins impose a set of pretty harsh 
constraints on your build environment for plugins work with the program that is supposed to load them:

1. The plugin Go compiler version must exactly match the program's compiler version. For example, loading a plugin 
compiled with Go 1.12.9 will not work with a program compiled with 1.12.8. The flags provided during compilation must match 
as well.
2. Any libraries that are shared by both the plugin and the program must have their versions match *exactly*. Moreover, 
these libraries must be compiled with the same `GOPATH` value when building both the plugin and the program.
3. Both the plugins and the program need to be built with CGO_ENABLED=1. Cross compiling isn't as easy as 
`GOARCH=amd64 GOOS=linux go build` anymore.

If any of the above conditions is not met, loading the plugin will fail.

All these constraints can make plugin development pretty frustrating. This is why we provide a set of tools that are 
meant make your plugin development experience as smooth as possible. You can find these tools in our 
[Ext Auth Plugin examples](https://github.com/solo-io/ext-auth-plugin-examples) GitHub repository.

{{% notice note %}}
Gloo publishes information about the environment it was build with to a Google Storage bucket. The tools in this section 
will make use of those information. You can find the information for a specific Gloo version in the following files located 
under `http://storage.googleapis.com/gloo-ee-dependencies/[GLOOE_VERSION]`:

- `Gopkg.lock`: contains the versions of all dependencies used by GlooE.
- `build_env`: values that can be used to replicate the environment the given GlooE version was built in.
- `verify-plugins-linux-amd64`: a script to verify that the plugin can be loaded by the given GlooE version.

You can get all these files by running `GLOOE_VERSION=desired_version make get-glooe-info` in our example repository.
{{% /notice %}}

#### Compare dependencies
We manage Gloo dependencies using [dep](https://github.com/golang/dep). `Dep` outputs the version of all dependencies 
for a Go package in a file named `Gopkg.lock`. If you manage the dependencies for your plugin using `dep`, we provide a 
script for comparing them with the ones for GlooE. It located at `scripts/compare_dependencies.go` and can be invoked 
via the following `make` command:

```bash
GLOOE_VERSION=desired_version make compare-deps`
```

If all dependencies match, the command will exit with a zero code, else it will output the discrepancies to both stdout 
and to a file (`mismatched_dependencies.json`) and exit with code 1. Here's an example of the output in case of failure:

```json
[
  {
    "pluginDependencies": {
      "name": "go.uber.org/zap",
      "version": "v1.9.0",
      "revision": "3c4937480c32f4c13a875a1829af76c98ca3d40a"
    },
    "glooeDependencies": {
      "name": "go.uber.org/zap",
      "version": "v1.10.0",
      "revision": "27376062155ad36be76b0f12cf1572a221d3a48c"
    }
  }
]
```

If you get an error message like this, you have to manually update the dependencies in your `Gopkg.toml` file. In this 
case we would need to add the following stanza:

```toml
[[override]]
  name = "go.uber.org/zap"
  version = "=v1.10.0"
```

or, even better since the revision hash is the ultimate source of truth:

```toml
[[override]]
  name = "go.uber.org/zap"
  revision = "27376062155ad36be76b0f12cf1572a221d3a48c"
```

If you are using a different dependency management tool (e.g. Go modules), you should still be able to use the 
information in the GlooE `Gopkg.lock` file to verify that the dependencies match.
  
#### Verify compatibility script
As part of each GlooE release, we ship a script to verify whether your plugin can be loaded by that version of GlooE. 
You can find it in the aforementioned Google Cloud bucket at 
`http://storage.googleapis.com/gloo-ee-dependencies/[GLOOE_VERSION]/verify-plugins-linux-amd64`. The script accepts 
three arguments:

| Arg Name | Description | Optional |
| ---- | ----------- | -------- |
| pluginDir | Path to a directory containing the plugin `.so` files to verify |  No |
| manifest | A .yaml file containing information required to load the plugins | No |
| debug | Set debug log level | Yes |

The `manifest` file is needed to instruct the script on how to load the plugins. It intentionally has the same format as 
the plugin configuration that you define on your Virtual Services:

```yaml
plugins:
- name: MyPlugin
  pluginFileName: Plugin.so
  exportedSymbolName: MyPlugin
- name: AnotherPlugin
  plugin_file_name: AnotherFile.so
  exported_symbol_name: AnotherSymbol
```

Here is the sample output of a successful run of the script:

```text
{"level":"info","ts":"2019-08-21T17:02:22.803Z","logger":"verify-plugins.header_value_plugin","caller":"pkg/impl.go:39","msg":"Parsed RequiredHeaderAuthService config","requiredHeader":"my-auth-header","allowedHeaderValues":["foo","bar","baz"]}
{"level":"info","ts":"2019-08-21T17:02:22.803Z","logger":"verify-plugins","caller":"plugins/loader.go:85","msg":"Successfully loaded plugin. Adding it to the plugin chain.","pluginName":"RequiredHeader"}
{"level":"info","ts":"2019-08-21T17:02:22.803Z","logger":"verify-plugins","caller":"scripts/verify_plugins.go:62","msg":"Successfully verified that plugins can be loaded by Gloo!"}
```

{{% notice note %}}
The script is compiled to run on `linux` with `amd64` architectures. We will explain how it is supposed to be used in the next section.
{{% /notice %}}
 
#### Docker file
We mentioned that the plugin must be compiled with the same `GOPATH` as Gloo. We also cannot easily cross-compile with 
`go build` because we need to run with CGO enabled. The best way to get around these constraints is to compile inside a 
container.

The example repository contains a [Dockerfile](https://github.com/solo-io/ext-auth-plugin-examples/blob/master/Dockerfile),
which we include here since all of it is relevant. See the comments for an explanation of each build layer:

```Dockerfile
# This stage is parametrized to replicate the same environment GlooE was built in.
# All ARGs need to be set via the docker `--build-arg` flags.
ARG GO_BUILD_IMAGE
FROM $GO_BUILD_IMAGE AS build-env

# This must contain the value of the `gcflag` build flag that Gloo was built with
ARG GC_FLAGS
# This must contain the path to the plugin verification script
ARG VERIFY_SCRIPT

# Fail if VERIFY_SCRIPT not set
# We don't have the same check GC_FLAGS as empty values are allowed
RUN if [[ ! $VERIFY_SCRIPT ]]; then echo "Required VERIFY_SCRIPT build argument not set" && exit 1; fi

# Install packaes needed for compilation
RUN apk add --no-cache gcc musl-dev

# Copy the repository to the image and set it as the working directory. The GOPATH her is `/go`.
#
# You have to update the path here to the one corresponding to your repository. This is usually in the form:
# /go/src/github.com/YOUR_ORGANIZATION/PLUGIN_REPO_NAME
ADD . /go/src/github.com/solo-io/ext-auth-plugin-examples/
WORKDIR /go/src/github.com/solo-io/ext-auth-plugin-examples

# De-vendor all the dependencies and move them to the GOPATH, so they will be loaded from there.
# We need this so that the import paths for any library shared between the plugins and Gloo are the same.
#
# For example, if we were to vendor the ext-auth-plugin dependency, the ext-auth-server would load the plugin interface
# as `GLOOE_REPO/vendor/github.com/solo-io/ext-auth-plugins/api.ExtAuthPlugin`, while the plugin
# would instead implement `THIS_REPO/vendor/github.com/solo-io/ext-auth-plugins/api.ExtAuthPlugin`. These would be seen 
# by the go runtime as two different types, causing Gloo to fail.
# Also, some packages cause problems if loaded more than once. For example, loading `golang.org/x/net/trace` twice
# causes a panic (see here: https://github.com/golang/go/issues/24137). By flattening the dependencies this way we
# prevent these sorts of problems.
RUN cp -a vendor/. /go/src/ && rm -rf vendor

# Build plugins with CGO enabled, passing the GC_FLAGS flags
RUN CGO_ENABLED=1 GOARCH=amd64 GOOS=linux go build -buildmode=plugin -gcflags="$GC_FLAGS" -o plugins/RequiredHeader.so plugins/required_header/plugin.go

# Run the script to verify that the plugin(s) can be loaded by Gloo
RUN chmod +x $VERIFY_SCRIPT
RUN $VERIFY_SCRIPT -pluginDir plugins -manifest plugins/plugin_manifest.yaml

# This stage builds the final image containing just the plugin .so files. It can really be any linux/amd64 image.
FROM alpine:3.10.1

# Copy compiled plugin file from previous stage
RUN mkdir /compiled-auth-plugins
COPY --from=build-env /go/src/github.com/solo-io/ext-auth-plugin-examples/plugins/RequiredHeader.so /compiled-auth-plugins/

# This is the command that will be executed when the container is run. 
# It has to copy the compiled plugin file(s) to a directory. TODO document dir
CMD cp /compiled-auth-plugins/* /auth-plugins/
```

We recommend that you use [multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/) to keep 
the size of your final image to a minimum.

#### Wrapping it up

## 
