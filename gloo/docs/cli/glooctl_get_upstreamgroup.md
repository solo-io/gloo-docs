---
title: "glooctl get upstreamgroup"
weight: 5
---
## glooctl get upstreamgroup

read an upstream group or list upstream groups in a namespace

### Synopsis

usage: glooctl get upstreamgroup [NAME] [--namespace=namespace] [-o FORMAT]

```
glooctl get upstreamgroup [flags]
```

### Options

```
  -h, --help   help for upstreamgroup
```

### Options inherited from parent commands

```
      --consul-address string      address of the Consul server. Use with --use-consul (default "127.0.0.1:8500")
      --consul-datacenter string   Datacenter to use. If not provided, the default agent datacenter is used. Use with --use-consul
      --consul-root-key string     key prefix for for Consul key-value storage. (default "gloo")
      --consul-scheme string       URI scheme for the Consul server. Use with --use-consul (default "http")
      --consul-token string        Token is used to provide a per-request ACL token which overrides the agent's default token. Use with --use-consul
  -i, --interactive                use interactive mode
      --name string                name of the resource to read or write
  -n, --namespace string           namespace for reading or writing resources (default "gloo-system")
  -o, --output OutputType          output format: (yaml, json, table, kube-yaml, wide) (default table)
      --use-consul                 use Consul Key-Value storage as the backend for reading and writing config (VirtualServices, Upstreams, and Proxies)
```

### SEE ALSO

* [glooctl get](../glooctl_get)	 - Display one or a list of Gloo resources

