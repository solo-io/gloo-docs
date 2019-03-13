---
title: Gloo Command Line Tool
weight: 1
description: A command line tool that all Gloo users should have and use to make their lives easier.
---

## Options for installing Gloo command line tool
## Installing Enterprise `glooctl` {#enterprise}

Download the CLI Command appropriate to your environment:

* [MacOs]( {{% siteparam "glooctl-darwin" %}})
* [Linux]( {{% siteparam "glooctl-linux" %}})
* [Windows]( {{% siteparam "glooctl-windows" %}})

{{% notice note %}}
To facilitate usage we recommend renaming the file to **`glooctl`** and adding the CLI to your PATH.
{{% /notice %}}

If your are running Linux or MacOs, make sure the `glooctl` is an executable file by running:

```shell
chmod +x glooctl
```

Verify that you have the Enterprise version of the `glooctl` by running:

```shell
glooctl --version
```

You should see a version statement like `glooctl enterprise edition version 0.10.7`

## Next Steps

**[Install Gloo!](../install_kubernetes)**