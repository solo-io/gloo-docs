---
title: "glooctl edit upstream"
weight: 5
---
## glooctl edit upstream

edit an upstream in a namespace

### Synopsis

usage: glooctl edit upstream [NAME] [--namespace=namespace]

```
glooctl edit upstream [flags]
```

### Options

```
  -h, --help                          help for upstream
      --ssl-remove                    Remove SSL configuration from this upstream
      --ssl-secret-name string        name of the ssl secret for this upstream
      --ssl-secret-namespace string   namespace of the ssl secret for this upstream
      --ssl-sni string                SNI value to provide when contacting this upstream
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
      --resource-version string    the resource version of the resource we are editing. if not empty, resource will only be changed if the resource version matches
      --use-consul                 use Consul Key-Value storage as the backend for reading and writing config (VirtualServices, Upstreams, and Proxies)
```

### SEE ALSO

* [glooctl edit](../glooctl_edit)	 - Edit a Gloo resource

