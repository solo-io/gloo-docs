---
title: Install Gloo CLI glooctl
weight: 1
---

## Options for installing Gloo command line tool

* [Install Open Source](#open-source)
* [Install Enterprise](#enterprise)

---

## Installing Open Source `glooctl` {#open-source}

To install the CLI, run the following.

```bash
curl -sL https://run.solo.io/gloo/install | sh
```

Alternatively, you can download the CLI directly [via the github releases page](https://github.com/solo-io/gloo/releases).

Next, add Gloo to your path, for example:

```bash
export PATH=$HOME/.gloo/bin:$PATH
```

Verify the CLI is installed and running correctly with:

```bash
glooctl --version
```

---

## Installing Enterprise `glooctl` {#enterprise}

Download the CLI Command appropriate to your environment:

* [MacOs]( {{% siteparam "glooctl-darwin" %}})
* [Linux]( {{% siteparam "glooctl-linux" %}})
* [Windows]( {{% siteparam "glooctl-windows" %}})

{{% notice note %}}
To facilitate usage we recommend renaming the file to **`glooctl`** and adding the CLI to your PATH.
{{% /notice %}}

If your are running Linux or MacOs, make sure the `glooctl` is an executable file by running:

```bash
chmod +x glooctl
```

Verify that you have the Enterprise version of the `glooctl` by running:

```bash
glooctl --version
```

You should see a version statement like `glooctl enterprise edition version 0.10.4`

## Next Steps

**[Install Gloo!](../../installation)**