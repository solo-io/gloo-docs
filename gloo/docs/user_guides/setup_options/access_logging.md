---
title: Access Logging
weight: 10
description: How to configure access logging for your Gloo proxy
---

Gloo can be configured to provide extensive Access Logging from envoy. These logs can be configured for 
HTTP (L7) connections as well at TCP (L4).


# Access Logging

The envoy documentation on Access Logging can be found [here](https://www.envoyproxy.io/docs/envoy/v1.10.0/configuration/access_log#config-access-log-default-format)

#### Usage

Access Logging allows for more verbose, customizable Usage logs from envoy. These logs will not replace the normal logs outputted by envoy, but can be used instead to supplement them. 
Possible use cases include:

*  specially formatted string logs
*  formatted JSON logging to be ingested by log aggregators
*  GRPC streaming of logs to external services (future update)

#### Configuration

The following explination assumes that the user has gloo `v0.18.1` or above running, as well as some previous knowledge of Gloo resources, and how to use them. In order to install Gloo if it is not already please refer to the following [tutorial](../../../installation/gateway/kubernetes). The only Gloo resource involved in enabling Access Loggins is the `Gateway`. Further Documentation can be found [here]().

Enabling access logs in Gloo is as simple as adding a [listener plugin](../../gateway/configuring_route_options/listener_plugins) to any one of the gateway resources. The documentation for the `Access Logging Service` plugin API can be found [here]({{% ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/plugins/als/als.proto.sk" %}}).

Envoy supports two types of Access Logging. `File Sink` and `GRPC`. Currently Gloo supports `File Sink` with plans to add GRPC streaming in the future.

Within the `File Sink` category of Access Logs there are 2 options for output, those being:

* [String formatted](#string-formatted)
* [JSON formatted](#json-formatted)

These are mutually exclusive for a given Access Logging configuration, but any number of access logging configurations can be applied to any place in the API which supports Access Logging. All `File Sink` configurations also accept a file path which envoy logs to. If the desired behavior is for these logs to output to `stdout` along with the other envoy logs then use the value `/dev/stdout` as the path.

The documentation on envoy formatting directives can be found [here](https://www.envoyproxy.io/docs/envoy/v1.10.0/configuration/access_log#format-dictionaries)

##### String formatted

An example config for string formatted logs is as follows:
{{< highlight yaml "hl_lines=14-19" >}}
apiVersion: gateway.solo.io.v2/v2
kind: Gateway
metadata:
  annotations:
    origin: default
  name: gateway
  namespace: gloo-system
spec:
  bindAddress: '::'
  bindPort: 8080
  gatewayProxyName: gateway-proxy-v2
  httpGateway: {}
  useProxyProto: false
  plugins:
    accessLoggingService:
      accessLog:
      - fileSink:
          path: /dev/stdout
          stringFormat: ""
{{< / highlight >}}


The above yaml also includes the Gateway object it is contained in. Notice that the `stringFormat` field above is set to `""`. This is intentional. If the string is set to `""` envoy will use a standard formatting string. More information on this as well as how to create a customized string see [here](https://www.envoyproxy.io/docs/envoy/v1.10.0/configuration/access_log#default-format-string).

##### JSON formatted

An example config for JSON formatted logs is as follows:

{{< highlight yaml "hl_lines=14-21" >}}
apiVersion: gateway.solo.io.v2/v2
kind: Gateway
metadata:
  annotations:
    origin: default
  name: gateway
  namespace: gloo-system
spec:
  bindAddress: '::'
  bindPort: 8080
  gatewayProxyName: gateway-proxy-v2
  httpGateway: {}
  useProxyProto: false
  plugins:
    accessLoggingService:
      accessLog:
      - fileSink:
          path: /dev/stdout
          jsonFormat:
            protocol: "%PROTOCOL%"
            duration: "%DURATION%"
{{< / highlight >}}

The majority is the same as the above, as the gateway has the same config, the differece exists in the formatting of the file sink. Instead of a simple string formatting directive, this config accepts an object value which is transformed by envoy into JSON formatted logs. The object inside of the `jsonFormat` field is interperted as a JSON object. This object consists of nested json objects as well as keys which point to individual formatting directives. More documentation on JSON formatting can be found [here](https://www.envoyproxy.io/docs/envoy/v1.10.0/configuration/access_log#format-dictionaries).

