---
title: "glooctl edit upstream"
weight: 5
---
## glooctl edit upstream

read an upstream or list upstreams in a namespace

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
  -i, --interactive               use interactive mode
      --name string               name of the resource to read or write
  -n, --namespace string          namespace for reading or writing resources (default "gloo-system")
  -o, --output string             output format: (yaml, json, table)
      --resource-version string   the resource version of the resouce we are editing. if not empty, resource will only be changed if the resource version matches
```

### SEE ALSO

* [glooctl edit](../glooctl_edit)	 - Edit a Gloo resource

