---
title: Authentication (Enterprise)
weight: 30
description: Gloo has a few different options for Authentication; choose the one that best suits your use case.
---

### Why Authenticate in API Gateway Environments
API Gateways act as a control point for the outside world to access the various application services 
(monoliths, microservices, serverless functions) running in your environment. In microservices or hybrid application 
architecture, any number of these workloads will need to accept incoming requests from external end users (clients). 
Incoming requests can be treated as anonymous or authenticated and depending on the service, you may want to 
establish and validate who the client is, the service they are requesting and define any access or traffic 
control policies.

### Authentication in Gloo
Gloo Enterprise provides a variety of authentication options to meet the needs of your environment. They range from 
supporting basic use cases to complex and fine grained secure access control. Architecturally, Gloo uses a dedicated
auth server to verify the user credentials and determine their permissions. Gloo provides an auth server that can support 
several authN/Z implementations, but also allows you to provide your own auth server to implement custom logic. 

#### Sidecar mode
By default, Gloo's built-in Auth Server is deployed as its own Kubernetes pod. This means that, in order to 
authenticate a request, Gloo (which runs in a separate pod) needs to communicate with the service over the network.
In case you deem this overhead not to be acceptable for your use case, you can deploy the server in **sidecar mode**.

In this configuration, the Ext Auth server will run as an additional container inside the `gateway-proxy` pod(s) that run 
Gloo's Envoy instance(s) and communication with Envoy will occur via Unix Domain Sockets instead of TCP. This cuts out 
the overhead associated with the TCP protocol and can provide huge performance benefits (40%+ in some benchmarks).

You can activate this mode by [installing Gloo with Helm]({{< ref "installation/enterprise#installing-on-kubernetes-with-helm" >}})
and providing the following value override:

| option                                                    | type     | description                                                                                                                                                                                                                                                    |
| --------------------------------------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| global.extensions.extAuth.envoySidecar                    | bool     | Deploy ext-auth as a sidecar to Envoy instances. Communication occurs over Unix Domain Sockets instead of TCP. Default is `false` |

#### Configuration overview

{{% notice info %}}
{{< readfile file="/static/content/extauth_version_info_note" >}}
{{% /notice %}}

Authentication configuration is defined in [AuthConfig]({{< ref "/api/github.com/solo-io/gloo/projects/gloo/api/v1/enterprise/plugins/extauth/v1/extauth.proto.sk#authconfig" >}}) resources. 
`AuthConfig`s are top-level resources, which means that if you are running in Kubernetes, they will be stored in a dedicated CRD.
Here is an example of a simple `AuthConfig` CRD:


```yaml
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
            hashedPassword: 14o4fMw/Pm2L34SvyyA2r.
            salt: 0adzfifo
      realm: gloo
```

The resource `spec` consists of an array of `configs` that will be executed in sequence when a request matches the 
`AuthConfig` (more on how requests are matched to `AuthConfigs` shortly). If any one of these "authentication steps" 
fails, the request will be denied. In most cases an `AuthConfig` will contain a single `config`.

##### Configuration format
Once an `AuthConfig` has been created, it can be used to authenticate your `Virtual Services` (or on the lower-level `Proxy` resources). 
You can define authentication configuration your Virtual Services at three different levels:
 
- on **VirtualHosts**,
- on **Routes**, and
- on **WeightedDestinations**.

The configuration format is the same in all three cases. It must be specified under the relevant `plugins` attribute 
(`VirtualHostPlugins`, `RoutePlugins`, or `WeightedDestinationPlugins`) and can take one of two forms. 
The first is used to enable authentication and requires you to reference an existing `AuthConfig`. An example Virtual Host 
configuration of this kind is the following:

```yaml
virtualHostPlugins:
  extensions:
    configs:
      extauth:
        config_ref:
          # references the example AuthConfig we defined earlier
          name: basic-auth
          namespace: gloo-system
```

In case of a route or weighted destination the top attribute would be names `routePlugins` and `weightedDestinationPlugins` respectively.

The second form is used to explicitly disable authentication:

```yaml
virtualHostPlugins: #  use `routePlugins` or `weightedDestinationPlugins` for routes or weighted destinations respectively
  extensions:
    configs:
      extauth:
        config_ref:
          disabled: true
```

##### Inheritance rules
By default, an `AuthConfig` defined on a `Virtual Service` attribute is inherited by all the child attribute:

- `AuthConfig`s defined on `VirtualHosts` are inherited by `Route`s and `WeightedDestination`s.
- `AuthConfig`s defined on `Route`s are inherited by `WeightedDestination`s.

There are two exceptions to this rule:

- if the child attribute attribute defines its own `AuthConfig`, or
- if the child explicitly disables authentication via the `disabled: true` configuration.

#### Implementations
We have seen how `AuthConfigs` can be used to define granular authentication configurations for `Virtual Services`. For 
a detailed overview of the authN/authZ models implemented by Gloo, check out our individual guides:

{{% children description="true" %}}
