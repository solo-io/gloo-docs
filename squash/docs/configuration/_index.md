---
title: Configuration
weight: 20
---

Squash can be used without any configuration. For convenience, or to take advantage of certain IDE and debugger features, you can configure various parameters.

### Source code mapping

Source code mapping tells your debugger how to translate filepaths from your local environment to filepaths on the process that you are trying to debug. If you compiled and deployed the process that you are debugging, source path mapping should not be required. However, if you are debugging a process that was compiled by a teammate or an automated release process, you need to tell your debugger how a breakpoint set on your local source file should be applied to the process you are debugging.

For example, let's say I am trying to debug a service that my teammate Yuval compiled and deployed.

- The service:
  - The service is hosted in our code repo at `github.com/solo-io/squash/contrib/example/service1`.
  - We want to debug a `handler` function in `github.com/solo-io/squash/contrib/example/service1/main.go`.
- The running process:
  - Yuval cloned the source to his local environment, he put it in `/home/yuval/go/src`.
  - The full path to the `main.go` file is `/home/yuval/go/src/github.com/solo-io/squash/contrib/example/service1/main.go`
  - Yuval compiles this service (with debug flags enabled) so the full path to the function is `/home/yuval/go/src/github.com/solo-io/squash/contrib/example/service1/main.go:handler`
- The local environment:
  - To debug this service, I first clone the source code to my local environment.
  - Now I have access to the code in `/Users/mitch/go/src/github.com/solo-io/squash/contrib/example/service1/main.go`
  - I want to open a breakpoint on the `handler` function in `main.go`. To do so, I select `/Users/mitch/go/src/github.com/solo-io/squash/contrib/example/service1/main.go:handler`.
  - I need to tell the debugger how to map my break point specification to the equivalent source path on the target process.
- The source code mapping:

```
# Note the similarity between these two paths:
/home/yuval/go/src/github.com/solo-io/squash/contrib/example/service1/main.go
/Users/mitch/go/src/github.com/solo-io/squash/contrib/example/service1/main.go

# These paths are identical from this point on:
/home/yuval/
/Users/mitch/

# They both share this path:
go/src/github.com/solo-io/squash/contrib/example/service1/main.go
```

Depending on the IDE and debugger you are using, you can specify source code mapping one of these two ways:

- **Method 1:** Specify the "from" and "to" paths [this is how `dlv` path substitution in `squashctl` works]
  - In this case, you can choose the minimum unique path identifiers
  - For example:

```
# This is the minimum path specification required:
From: /Users/mitch/
To:   /home/yuval/
# This will also work:
From: /Users/mitch/go/src/github.com/solo-io/squash/
To: /home/yuval/go/src/github.com/solo-io/squash/
```

- **Method 2:** Infer the "From" path from the "workspace" directory that you have opened [this is how path substitution works in `vscode`]
  - In this case, you must specify a substitution that replaces your "workspace" path with the equivalent target path.
  - For example:

```
# workspace: /Users/mitch/go/src/github.com/solo-io/squash/contrib/example/service1/
 substitute: /home/yuval/go/src/github.com/solo-io/squash/contrib/example/service1/
# workspace: /Users/mitch/go/src/github.com/solo-io/squash/
 substitute: /home/yuval/go/src/github.com/solo-io/squash/
# workspace: /Users/mitch/
 substitute: /home/yuval/
```

{{% notice note %}}
Remember to include the trailing `/` (or `\` on Windows) in your path substitution spec. Some debuggers perform substitutions literally, which may produce `/home/localsrc` when you intended `home/local/src`.
{{% /notice %}}

#### Visual Studio Code

- Visual studio code handles path substitution in terms of its workspace (as described above).
- Just set the `squash.remotePath` to the corresponding path for the target process.

### Squash Binary

- We make frequent updates to Squash, `squashctl`, the Plank pods, and the IDE extensions. You can download the latest version from our [releases page](https://github.com/solo-io/squash/releases).

#### Visual Studio Code

- The Squash extension for Visual studio code can download updates to `squashclt` for you. When updates are available, a prompt will offer to download the latest release.
- If you prefer to use a particular version of `squashctl`, you can specify its path with `squash.path`.`
