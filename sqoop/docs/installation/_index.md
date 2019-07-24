---
weight: 10
title: Installation
---

# Installing with `sqoopctl`

## What you'll need

1. Kubernetes v1.8+ or higher deployed. We recommend using [minikube](https://kubernetes.io/docs/getting-started-guides/minikube/) to get a demo cluster up quickly.
2. [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/) installed on your local machine.
3. `sqoopctl` installed on your local machine.

### Installing sqoopctl

If you use [Homebrew](https://brew.sh) package manager you can install with the following command

```shell
brew install solo-io/tap/sqoopctl
```

You can also install by downloading from the Sqoop releases page <https://github.com/solo-io/sqoop/releases/>.

### Installing into Kubernetes

Once your Kubernetes cluster is up and running, run the following command to deploy Sqoop and Gloo to the `gloo-system` namespace:

```bash
sqoopctl install kube
```

## Confirming the installation

Check that the Sqoop pods and services have been created:

```bash
kubectl get all --namespace gloo-system
```

```noop
NAME                                READY   STATUS    RESTARTS   AGE
pod/discovery-5895887d99-cks9p      1/1     Running   0          36s
pod/gateway-6c585777dc-9w7n2        1/1     Running   0          36s
pod/gateway-proxy-b4fdb8745-hv4m2   1/1     Running   0          36s
pod/gloo-8664fbb995-lsqbg           1/1     Running   0          36s
pod/sqoop-58d78b6fbb-kkdrb          2/2     Running   0          36s

NAME                    TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
service/gateway-proxy   LoadBalancer   10.107.33.233    <pending>     80:32659/TCP,443:31205/TCP   36s
service/gloo            ClusterIP      10.105.77.113    <none>        9977/TCP                     36s
service/sqoop           LoadBalancer   10.103.254.252   <pending>     9095:31985/TCP               36s

NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/discovery       1/1     1            1           36s
deployment.apps/gateway         1/1     1            1           36s
deployment.apps/gateway-proxy   1/1     1            1           36s
deployment.apps/gloo            1/1     1            1           36s
deployment.apps/sqoop           1/1     1            1           36s

NAME                                      DESIRED   CURRENT   READY   AGE
replicaset.apps/discovery-5895887d99      1         1         1       36s
replicaset.apps/gateway-6c585777dc        1         1         1       36s
replicaset.apps/gateway-proxy-b4fdb8745   1         1         1       36s
replicaset.apps/gloo-8664fbb995           1         1         1       36s
replicaset.apps/sqoop-58d78b6fbb          1         1         1       36s
```

Everything should be up and running. If this process does not work, please [open an issue](https://github.com/solo-io/sqoop/issues/new). We are happy to answer
questions on our [diligently staffed Slack channel](https://slack.solo.io/).

See [Getting Started on Kubernetes](../getting_started) to get started creating your first GraphQL endpoint with Sqoop.
