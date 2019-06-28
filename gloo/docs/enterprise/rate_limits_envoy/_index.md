---
title: Envoy Rate Limits
description: Advanced Rate Limit configuration.
weight: 3
---

In this document, we will show how to use Gloo with [Envoy's rate-limit API](https://www.envoyproxy.io/docs/envoy/latest/configuration/http_filters/rate_limit_filter). We make the distinction here that this is "Envoy's" rate-limit API because Gloo [offers a much simpler rate-limit API](../ratelimit) as an alternative. 

Gloo enterprise comes with a rate limit server based on [Lyft's Envoy rate-limit server](https://github.com/lyft/ratelimit). It is already installed when doing `gloo install gateway --license-key=...`
To get your trial license key, go to: https://www.solo.io/glooe-trial

Gloo supports two modes of rate limits:

- A [simple mode](../ratelimit) that allows configuring limits for authenticated (as defined by the [Gloo auth plugin](../authentication)) and anonymous requests.
- A custom mode that allows configuring limits with the [native Envoy configuration language](https://www.envoyproxy.io/docs/envoy/latest/configuration/http_filters/rate_limit_filter).

In this document, we will describe the second option (The first option is easily accessible via the UI, and described in [this doc](../ratelimit)).

## Setup - Installing Gloo 
This is covered by [other parts of the documentation](../installation), here is the quick version:

```bash
$ glooctl install gateway --license-key=<YOUR KEY>
```

Install the pet clinic demo app:

```bash
$ kubectl apply -f https://raw.githubusercontent.com/solo-io/gloo/master/example/petclinic/petclinic.yaml
```

Add a route to the petclinic demo app:

```bash
$ glooctl add route --name default --namespace gloo-system --path-prefix / --dest-name default-petclinic-8080 --dest-namespace gloo-system
```

Check that everything is in order:
```bash
$ URL=$(glooctl proxy url)
$ curl --head $URL 
HTTP/1.1 200 OK
content-type: text/html;charset=UTF-8
content-language: en
content-length: 3939
date: Sun, 17 Mar 2019 15:42:04 GMT
x-envoy-upstream-service-time: 13
server: envoy
```

## Configuring Envoy Rate Limits

The glooctl command line will open a text editor so you can write your custom configuration directly.
To use your favorite editor, set the `EDITOR` environment variable.

For example, when using vscode:
```bash
$ export EDITOR="code -r -w"
```

### Edit Rate Limit Server Settings
Edit the rate limit server settings:
```bash
$ glooctl edit settings --namespace gloo-system --name default ratelimit custom-server-config
```

This will open the rate limit server configuration in your editor. Paste this configuration block there:
```yaml
descriptors:
  - key: generic_key
    value: some_value
    rate_limit:
         requests_per_unit: 1
         unit: minute
```

For your convenience, you can download it [here](serverconfig.yaml).

The structure of the rate limit server configuration is a list of hierarchal limit descriptors. For more information, see [here](https://github.com/lyft/ratelimit).

#### Behavior on failure
Envoy queries an external server (backed by redis) to achive global rate limiting.
You can set a timeout for the query, and what to do in case the query fails.
By default, the timeout is set to 100ms, and the failure policy is to allow the request.

{{% notice tip %}}
You can check if envoy has errors with rate limiting by examining its stats that end in `ratelimit.error`.
`glooctl proxy stats` will display the stats from one of the envoys in your cluster. 
{{% /notice %}}

To change the timeout to 200ms, use this command:
```bash
glooctl edit settings --name default --namespace gloo-system ratelimit --request-timeout=200ms
```

To deny requests when there's an error querying the rate limit service, use this command:
```bash
glooctl edit settings --name default --namespace gloo-system ratelimit --deny-on-failure=true
```


### Edit Virtual Service Rate Limit Settings

Edit the virtual service settings:

```bash
$ glooctl edit virtualservice --namespace gloo-system --name default ratelimit custom-envoy-config
```


This will open the virtual service rate limit configuration in your editor. paste this configuration block there:
```yaml
rate_limits:
- actions:
  - generic_key:
      descriptor_value: "some_value"
```

For your convenience, you can download it [here](vsconfig.yaml).

The structure of the virtual service configuration is as described in the [envoy documentation](https://www.envoyproxy.io/docs/envoy/v1.9.0/api-v2/api/v2/route/route.proto#route-ratelimit-action). This configuration will be passed to envoy as is.

{{% notice note %}}
You can run the same command for a *route* as well (`glooctl edit route ...`). When providing configuration for a `route`, you can also specify a boolean `include_vh_rate_limits` to include the rate limit descriptors from the virtual service.
{{% /notice %}}
### Test

You can use `glooctl proxy url` to get Gloo proxy's external endpoint. 

Run `curl --head $URL` a few times. You will soon see that curl is rate limited:

```bash
$ curl --head $URL 
HTTP/1.1 429 Too Many Requests
x-envoy-ratelimited: true
date: Sun, 17 Mar 2019 15:42:17 GMT
server: envoy
transfer-encoding: chunked
```
## Conclusion
With the custom rate-limit configuration option, you have the full power of Envoy rate limits to use for your custom use cases. The downside to this is the API is a bit more complicated. To leverage a simpler API that can do true per-user (logged-in, authenticated user) rate limits, take a look at [Gloo's simplified ratelimit API](../ratelimit).
