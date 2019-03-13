---
title: Gloo Command Line Tool
weight: 1
description: A command line tool that all Gloo users should have and use to make their lives easier.
---

## Installing Gloo Command Line Tool

To install the CLI, run the following.

### [Homebrew](https://brew.sh/) package manager users

```shell
brew install glooctl
```

### All systems

```shell
curl -sL https://run.solo.io/gloo/install | sh
```

Alternatively, you can download the CLI directly [via the github releases page](https://github.com/solo-io/gloo/releases).

Next, add Gloo to your path, for example:

```shell
export PATH=$HOME/.gloo/bin:$PATH
```

## Verify Installation

Verify the CLI is installed and running correctly with:

```shell
glooctl --version
```

## Next Steps

**[Install Gloo!](../../installation)**