---
title: Kubernetes Ingress Object
weight: 5
description: Setting up Gloo to handle Kubernetes Ingress Objects.
---

Kubernetes Ingress Controllers are used for simple traffic routing into a kubernetes cluster. When Gloo is installed
with the `glooctl install ingress` command, Gloo will configure Envoy as a Kubernetes Ingress Controller, supporting
Ingress objects written with the annotation `kubernetes.io/ingress.class: gloo`.

If you need more advanced routing capabilities, we'd encourage you to use Gloo `VirtualServices` by installing as
`glooctl install gateway`. See the remaining routing documentation for more details on the extended capabilities Gloo
provides **without** needing to add lots of additional custom annotations to your Ingress Objects.

### What you'll need

* [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* Kubernetes v1.11.3+ deployed somewhere. [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) is a
great way to get a cluster up quickly.

### Steps

1. The Gloo Ingress [installed]({{< ref "/installation" >}}) and running on Kubernetes.

1. Next, deploy the Pet Store app to kubernetes:

    ```shell
    kubectl apply \
      --filename https://raw.githubusercontent.com/solo-io/gloo/master/example/petstore/petstore.yaml
    ```

1. Let's create a Kubernetes Ingress object to route requests to the petstore following the [Default Backend](https://kubernetes.io/docs/concepts/services-networking/ingress/#default-backend)
convention of not specifying host or path. Mode details can be found at [Kuberbetes Ingress Concepts](https://kubernetes.io/docs/concepts/services-networking/ingress/).

    Notice the `kubernetes.io/ingress.class: gloo` annotation that we've added.
    This indicates to Gloo that it should handle this Ingress Object.

    Also notice that the Kubernetes Ingress objects wants you to do special wildcarding of paths, `/.*`.

    {{< highlight noop "hl_lines=6-7 12" >}}
cat <<EOF | kubectl apply --filename -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
 name: petstore-ingress
 annotations:
    kubernetes.io/ingress.class: gloo
spec:
  rules:
  - http:
      paths:
      - path: /.*
        backend:
          serviceName: petstore
          servicePort: 8080
EOF
    {{< /highlight >}}

    ```noop
    ingress.extensions "petstore-ingress" created
    ```

1. Validate Ingress routing looks to be set up, and running.

    ```shell
    kubectl get ingress petstore-ingress
    ```

    ```noop
    NAME               HOSTS   ADDRESS   PORTS   AGE
    petstore-ingress   *                 80      18m
    ```

1. Let's test the route `/api/pets` using `curl`:

    ```shell
    export INGRESS_URL=$(glooctl proxy url --name ingress-proxy)
    curl ${INGRESS_URL}/api/pets
    ```

    ```json
    [{"id":1,"name":"Dog","status":"available"},{"id":2,"name":"Cat","status":"pending"}]
    ```

1. If you want to add server-side TLS to your Ingress, you can add it like the following. This assumes you've created
a TLS secret called `gateway-tls`, for example `kubectl create secret tls gateway-tls --cert=path/to/tls.cert --key=path/to/tls.key`

    {{< highlight yaml "hl_lines=8-11" >}}
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: petstore-ingress
  annotations:
    kubernetes.io/ingress.class: gloo
spec:
  tls:
  - hosts:
    - foo.bar.com
    secretName: gateway-tls
  rules:
  - http:
      paths:
      - path: /.*
        backend:
          serviceName: petstore
          servicePort: 8080
    {{< /highlight >}}

Great! Our ingress is up and running. See <https://kubernetes.io/docs/concepts/services-networking/ingress>
for more information on using Kubernetes Ingress Controllers.

Also recommend you look at [Gloo in gateway mode]({{% ref "http://localhost:1313/user_guides/basic_routing" %}}) for more advanced function routing options not available with Ingress
Object without adding lots of custom annotations.