---
title: Appending and Removing Request/Response Headers
menuTitle: Appending and Removing Headers
weight: 30
description: Append and Remove Headers from Requests and Responses using Route configuration.
---

Gloo can add and remove headers to/from requests and responses. We refer to this feature as "Header Manipulation".

Header Manipulation is configured via the 
[`headerManipulation`]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins/headers/headers.proto.sk.md#headermanipulation" %}}) struct.

This struct can be added to [Route Plugins]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins.proto.sk.md#routeplugins" %}}), [Virtual Host Plugins]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins.proto.sk.md#virtualhostplugins" %}}), and [Weighted Destination Plugins]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins.proto.sk.md#weighteddestinationplugins" %}}).

The `headerManipulation` struct contains four optional fields `requestHeadersToAdd`, `requestHeadersToRemove`,  `responseHeadersToAdd`, and `responseHeadersToRemove` :

```yaml
headerManipulation:

  # add headers to request
  requestHeadersToAdd:
  - header:
      key: HEADER_NAME
      value: HEADER_VALUE
    # if the header HEADER_NAME is already present,
    # append the value.
    append: true
  - header:
      key: HEADER_NAME
      value: HEADER_VALUE
    # if the header HEADER_NAME is already present,
    # overwrite the value.
    append: false

  # remove headers from request
  requestHeadersToRemove:
  - "HEADER_NAME"
  - "HEADER_NAME"

  # add headers to response
  responseHeadersToAdd:
  - header:
      key: HEADER_NAME
      value: HEADER_VALUE
    # if the header HEADER_NAME is already present,
    # append the value.
    append: true
  - header:
      key: HEADER_NAME
      value: HEADER_VALUE
    # if the header HEADER_NAME is already present,
    # overwrite the value.
    append: false

  # remove headers from response
  responseHeadersToRemove:
  - "HEADER_NAME"
  - "HEADER_NAME"
  

```

Depending on where the `headerManipulation` struct is added, the header manipulation will be applied on that level.

* When using `headerManipulation` in `routePlugins`,
headers will be manipulated for all traffic matching that route.

* When using `headerManipulation` in `virtualHostPlugins`,
headers will be manipulated for all traffic handled by the virtual host.

* When using `headerManipulation` in `weightedDestinationPlugins`,
headers will be manipulated for all traffic that is sent to the specific destination when it is selected for load balancing.

Envoy supports adding dynamic values to request and response headers. The percent symbol (%) is used to 
delimit variable names. See a list of the dynamic variables supported by Envoy in the [envoy docs](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#custom-request-response-headers).

## Example: Manipulating Headers on a Route


{{< highlight yaml "hl_lines=22-28" >}}
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  creationTimestamp: null
  name: 'default'
  namespace: 'gloo-system'
spec:
  virtualHost:
    domains:
    - '*'
    routes:
    - matcher:
        prefix: '/petstore'
      routeAction:
        single:
          upstream:
            name: 'default-petstore-8080'
            namespace: 'gloo-system'
      routePlugins:
        prefixRewrite:
          prefixRewrite: '/api/pets'
        headerManipulation:
          # add headers to all responses 
          # returned by this route
          responseHeadersToAdd:
          - header:
              key: HEADER_NAME
              value: HEADER_VALUE
status: {}
{{< /highlight >}}


## Example: Manipulating Headers on a VirtualHost

{{< highlight yaml "hl_lines=23-28" >}}
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  creationTimestamp: null
  name: 'default'
  namespace: 'gloo-system'
spec:
  virtualHost:
    domains:
    - '*'
    routes:
    - matcher:
        prefix: '/petstore'
      routeAction:
        single:
          upstream:
            name: 'default-petstore-8080'
            namespace: 'gloo-system'
      routePlugins:
        prefixRewrite:
          prefixRewrite: '/api/pets'
    virtualHostPlugins:
      headerManipulation:
        # remove headers from all requests 
        # handled by this virtual host
        requestHeadersToRemove:
        - "x-my-header"
        - "x-your-header"
status: {}
{{< /highlight >}}



## Example: Manipulating Headers on a Weighted Destination

{{< highlight yaml "hl_lines=28-35" >}}
apiVersion: gateway.solo.io/v1
kind: VirtualService
metadata:
  creationTimestamp: null
  name: 'default'
  namespace: 'gloo-system'
spec:
  virtualHost:
    domains:
    - '*'
    routes:
    - matcher:
        prefix: /myservice
      routeAction:
        multi:
          destinations:
          - weight: 9
            destination:
              upstream:
                name: default-myservice-v1-8080
                namespace: gloo-system
          - weight: 1
            destination:
              upstream:
                name: default-myservice-v2-8080
                namespace: gloo-system
            weightedDestinationPlugins:
              headerManipulation:
                # add headers to all requests
                # that are load balanced to `default-myservice-v2-8080`
                # on this route 
                requestHeadersToAdd:
                - header:
                    key: HEADER_NAME
                    value: HEADER_VALUE
status: {}
{{< /highlight >}}


