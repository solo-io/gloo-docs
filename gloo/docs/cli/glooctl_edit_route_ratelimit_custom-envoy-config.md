---
title: "glooctl edit route ratelimit custom-envoy-config"
weight: 5
---
## glooctl edit route ratelimit custom-envoy-config

Add a custom rate limit actions (Enterprise)

### Synopsis

This allows using envoy actions to specify your rate limit descriptors.
		For available actions and more information see: https://www.envoyproxy.io/docs/envoy/v1.9.0/api-v2/api/v2/route/route.proto#route-ratelimit-action
		
		This is a Gloo Enterprise feature.

```
glooctl edit route ratelimit custom-envoy-config [flags]
```

### Options

```
  -h, --help   help for custom-envoy-config
```

### Options inherited from parent commands

```
      --consul-address string      address of the Consul server. Use with --use-consul (default "127.0.0.1:8500")
      --consul-datacenter string   Datacenter to use. If not provided, the default agent datacenter is used. Use with --use-consul
      --consul-root-key string     key prefix for for Consul key-value storage. (default "gloo")
      --consul-scheme string       URI scheme for the Consul server. Use with --use-consul (default "http")
      --consul-token string        Token is used to provide a per-request ACL token which overrides the agent's default token. Use with --use-consul
  -x, --index uint32               edit the route with this index in the virtual service route list
  -i, --interactive                use interactive mode
      --name string                name of the resource to read or write
  -n, --namespace string           namespace for reading or writing resources (default "gloo-system")
  -o, --output OutputType          output format: (yaml, json, table, kube-yaml, wide) (default table)
      --resource-version string    the resource version of the resource we are editing. if not empty, resource will only be changed if the resource version matches
      --use-consul                 use Consul Key-Value storage as the backend for reading and writing config (VirtualServices, Upstreams, and Proxies)
```

### SEE ALSO

* [glooctl edit route ratelimit](../glooctl_edit_route_ratelimit)	 - Configure rate limit settings (Enterprise)

