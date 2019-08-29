---
title: "glooctl create upstream static"
weight: 5
---
## glooctl create upstream static

Create a Static Upstream

### Synopsis

Static upstreams are intended to connect Gloo to upstreams to services (often external or 3rd-party) running at a fixed IP address or hostname. Static upstreams require you to manually specify the hosts associated with a static upstream. Requests routed to a static upstream will be round-robin load balanced across each host.

```
glooctl create upstream static [flags]
```

### Options

```
  -h, --help                       help for static
      --service-spec-type string   if set, Gloo supports additional routing features to upstreams with a service spec. The service spec defines a set of features 
      --static-hosts strings       comma-separated list of hosts for the static upstream. these are hostnames or ips provided in the format IP:PORT or HOSTNAME:PORT. if :PORT is missing, it will default to :80
      --static-outbound-tls        connections Gloo manages to this cluster will attempt to use TLS for outbound connections. Gloo will automatically set this to true for port 443
```

### Options inherited from parent commands

```
      --consul-address string      address of the Consul server. Use with --use-consul (default "127.0.0.1:8500")
      --consul-datacenter string   Datacenter to use. If not provided, the default agent datacenter is used. Use with --use-consul
      --consul-root-key string     key prefix for for Consul key-value storage. (default "gloo")
      --consul-scheme string       URI scheme for the Consul server. Use with --use-consul (default "http")
      --consul-token string        Token is used to provide a per-request ACL token which overrides the agent's default token. Use with --use-consul
      --dry-run                    print kubernetes-formatted yaml rather than creating or updating a resource
  -i, --interactive                use interactive mode
      --name string                name of the resource to read or write
  -n, --namespace string           namespace for reading or writing resources (default "gloo-system")
  -o, --output OutputType          output format: (yaml, json, table, kube-yaml, wide) (default table)
      --use-consul                 use Consul Key-Value storage as the backend for reading and writing config (VirtualServices, Upstreams, and Proxies)
```

### SEE ALSO

* [glooctl create upstream](../glooctl_create_upstream)	 - Create an Upstream

