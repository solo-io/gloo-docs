---
title: "glooctl create upstreamgroup"
weight: 5
---
## glooctl create upstreamgroup

Create an Upstream Group

### Synopsis

Upstream groups represent groups of upstreams. An UpstreamGroup addresses an issue of how do you have multiple routes or virtual services referencing the same multiple weighted destinations where you want to change the weighting consistently for all calling routes. This is a common need for Canary deployments where you want all calling routes to forward traffic consistently across the two service versions.

```
glooctl create upstreamgroup [flags]
```

### Options

```
      --consul-address string        address of the Consul server. Use with --use-consul (default "127.0.0.1:8500")
      --consul-datacenter string     Datacenter to use. If not provided, the default agent datacenter is used. Use with --use-consul
      --consul-root-key string       key prefix for for Consul key-value storage. (default "gloo")
      --consul-scheme string         URI scheme for the Consul server. Use with --use-consul (default "http")
      --consul-token string          Token is used to provide a per-request ACL token which overrides the agent's default token. Use with --use-consul
  -h, --help                         help for upstreamgroup
      --use-consul                   use Consul Key-Value storage as the backend for reading and writing config (VirtualServices, Upstreams, and Proxies)
      --weighted-upstreams strings   comma-separated list of weighted upstream key=value entries (namespace.upstreamName=weight)
```

### Options inherited from parent commands

```
      --dry-run             print kubernetes-formatted yaml rather than creating or updating a resource
  -i, --interactive         use interactive mode
      --name string         name of the resource to read or write
  -n, --namespace string    namespace for reading or writing resources (default "gloo-system")
  -o, --output OutputType   output format: (yaml, json, table, kube-yaml, wide) (default table)
```

### SEE ALSO

* [glooctl create](../glooctl_create)	 - Create a Gloo resource

