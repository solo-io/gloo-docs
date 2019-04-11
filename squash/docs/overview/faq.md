---
title: FAQ
weight: 100
---

## Troubleshoot

### kubectl port-forward doesn't work

Sometimes kubectl port-forward may not work - as it needs a less restrictive network access.
For example, kubernetes deployed on AWS via kops, has tight security groups, and kubectl portforward will not work on a laptop outside AWS.

The solution for this is to provide it with a secure way in. Normally, ssh comes to the rescue. ssh can create a SOCKS proxy for us. However, kubectl doesn't support SOCKS proxy. Therefore, we use "polipo" to 'convert' the socks proxy to an http proxy.

ssh to a node on aws and create a socks proxy:

```
ssh -N -D 12346  admin@[NODE in the cluster here]
```

'convert' the socks proxy to an http proxy:

```
docker run --rm --net=host clue/polipo proxyAddress=127.0.0.1 proxyPort=12347 socksParentProxy="localhost:12346" socksProxyType=socks5 allowedPorts=1-65535 tunnelAllowedPorts=1-65535
```

then set an http proxy for kubectl.
You can do it as an env var before starting vscode:

```
export http_proxy=localhost:12347
```

Or you can use the "vs-squash.kubectl-proxy" setting in vscode. This setting is very focused and will only apply for the kubectl port-forward call.

kubectl port-forward will now work.

## Permissions

### Why does the squash client needs to be privileged?

The Plank needs to be privileged to be able to debug processes.

### Why does the squash client needs to be in the host pid namespace?

It needs to be in the hosts PID namespace and order to "see" the process to debug.

### Why does the squash client needs access to the CRI socket interface?

The squash client uses the CRI interface to understand what is the process-id of the container which we want to debug.

## Contact

### What information should I include in an issue?

- squash version
- kubectl version
- kubernetes/minikube version
- versions of any relevant debuggers or languages you are using

### How to submit patches?

Please use github's pull requests

### Community discussion

Please feel free to join the Squash chat in our [Slack channel](https://solo-io.slack.com/channels/squash)
