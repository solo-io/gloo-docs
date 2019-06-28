---
title: Kubernetes Ingress 
weight: 5
description: Setting up Gloo to handle Kubernetes Ingress Objects.
---

Kubernetes Ingress Controllers are for simple traffic routing in a Kubernetes cluster. Gloo supports managing Ingress
objects with the `glooctl install ingress` command, Gloo will configure Envoy as a Kubernetes Ingress Controller, supporting
Ingress objects annotated with the standard `kubernetes.io/ingress.class: gloo`.

If you need more advanced routing capabilities, we encourage you to use Gloo `VirtualServices` by installing as
`glooctl install gateway`. See the remaining routing documentation for more details on the extended capabilities Gloo
provides **without** needing to add lots of additional custom annotations to your Ingress Objects.

### What you'll need

* [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* Kubernetes v1.11.3+ deployed somewhere. [Minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) is a
great way to get a cluster up quickly.

## Basic Ingress Object managed by Gloo

### Steps

1. The Gloo Ingress [installed]({{< ref "/installation" >}}) and running on Kubernetes.

1. Next, deploy the Pet Store app to Kubernetes:

    ```shell
    kubectl apply \
      --filename https://raw.githubusercontent.com/solo-io/gloo/master/example/petstore/petstore.yaml
    ```

1. Let's create a Kubernetes Ingress object to route requests to the petstore following the [Default Backend](https://kubernetes.io/docs/concepts/services-networking/ingress/#default-backend)
convention of not specifying host or path. More details at [Kuberbetes Ingress Concepts](https://kubernetes.io/docs/concepts/services-networking/ingress/).

    Notice the `kubernetes.io/ingress.class: gloo` annotation that we've added, which indicates to Gloo that it should handle this Ingress Object.

    Also notice that the Kubernetes Ingress objects want you to do special wildcarding of paths, `/.*`.

    We're specifying a host `gloo.example.com` in this example. You should replace this with your domain, or do not
    include the host attribute at all to indicate all domains (`*`).

    {{< highlight noop "hl_lines=6-7 13" >}}
cat <<EOF | kubectl apply --filename -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
 name: petstore-ingress
 annotations:
    kubernetes.io/ingress.class: gloo
spec:
  rules:
  - host: gloo.example.com
    http:
      paths:
      - path: /.*
        backend:
          serviceName: petstore
          servicePort: 8080
EOF
    {{< /highlight >}}

1. Validate Ingress routing looks to be set up and running.

    ```shell
    kubectl get ingress petstore-ingress
    ```

    ```noop
    NAME               HOSTS              ADDRESS   PORTS   AGE
    petstore-ingress   gloo.example.com             80      14h
    ```

1. Let's test the route `/api/pets` using `curl`. The petstore service requires the query path `/api/pets` to access its
`findPets` REST function, so we'll need to append that to our `curl` requests. If you are running this against a cluster
with load balancing and DNS configured, then you should be able to access your domain directly.

    Make sure you set up your cloud provider LoadBalancer to connect to the `service/ingress-proxy` in the `gloo-system`
    namespace (or whatever namespace you deployed Gloo).

    ```shell
    curl http://gloo.example.com/api/pets
    ```

    If you are running this locally, e.g., in minikube, then you will need to do a little extra indirection to have `curl`
    send all the proper request headers.

    First, we'll need to get the local cluster IP address and port that Gloo is
    exposing for all Ingress objects. We can get the local cluster information using the
    `glooctl proxy url --name <ingress name>` command. So for our example running on a local minikube, you would see
    output similar to the following.

    ```shell
    glooctl proxy url --name ingress-proxy
    ```

    ```noop
    http://192.168.64.46:30949
    ```

    Then we can combine that information with a new capability of curl `--connect-to` to replace host and port
    information in the request connection while preserving request headers for host and sni. More details at
    [curl man page](https://curl.haxx.se/docs/manpage.html#--connect-to)

    ```shell
    curl --connect-to SOURCE_HOST:SOURCE_PORT:DESTINATION_HOST:DESTINATION_PORT http://SOURCE_HOST:SOURCE_PORT/your/query/path
    ```

    In this case, the Gloo proxy url gives us the destination host IP and port details, and your Ingress host setting is
    the SOURCE_HOST, and the SOURCE_PORT is 80 or 443 depending on if you've setup TLS (443) or not (80). More on setting up
    TLS for Ingress' later in this document. So using a little bit of command line magic to strip off the `http(s)://`
    prefix, you can run the following against your local cluster for our example ingress.

    ```shell
    export PROXY_HOST_PORT=$(glooctl proxy url --name ingress-proxy --port http | sed -n -e 's/^.*:\/\///p')
    curl --connect-to gloo.example.com:80:${PROXY_HOST_PORT} http://gloo.example.com/api/pets
    ```

    Either way you make the request you should see the following response from the petstore. If you have any issues,
    you can use `curl -v <rest of command>` to have it dump out more information about the request to help you debug
    the issue, e.g., are load balancers setup correctly, etc.

    ```json
    [{"id":1,"name":"Dog","status":"available"},{"id":2,"name":"Cat","status":"pending"}]
    ```

## TLS Configuration

Now if you want to use TLS with an Ingress Object managed by Gloo, here are the basic steps you need to follow.

1. You need to have a TLS key and certificate available as a Kubernetes secret. Let's create a self-signed one for our
example using `gloo.system.com` domain.

    ```shell
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout my_key.key -out my_cert.cert -subj "/CN=gloo.example.com/O=gloo.example.com"
    ```

    And then you need to create a tls secret in your Kubernetes cluster that your Ingress can reference

    ```shell
    kubectl create secret tls my-tls-secret --key my_key.key --cert my_cert.cert
    ```

1. If you want to add server-side TLS to your Ingress, you can add it as shown below. Note that it is important that the hostnames
match in both the `tls` section and in the `rules` that you want to be covered by TLS.

    {{< highlight yaml "hl_lines=9-12 14" >}}
cat <<EOF | kubectl apply --filename -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: petstore-ingress
  annotations:
    kubernetes.io/ingress.class: gloo
spec:
  tls:
  - hosts:
    - gloo.example.com
    secretName: my-tls-secret
  rules:
  - host: gloo.example.com
    http:
      paths:
      - path: /.*
        backend:
          serviceName: petstore
          servicePort: 8080
EOF
    {{< /highlight >}}

1. To validate, just like previously, if you're in a cluster with load balancers and DNS then you can call the test
example directly. Make sure that your load balancers are referencing the Gloo `service/ingress-proxy`.

    ```shell
    curl https://gloo.example.com/api/pets
    ```

    And for local clusters, we can do our `curl --connect-to` trick against a slightly different call to
    `glooctl proxy url --port https --name <ingress name>`. Note the `--port https` for TLS use cases.

    ```shell
    export PROXY_HOST_PORT=$(glooctl proxy url --name ingress-proxy --port https | sed -n -e 's/^.*:\/\///p')
    curl --cacert my_cert.cert --connect-to gloo.example.com:443:${PROXY_HOST_PORT} https://gloo.example.com/api/pets
    ```

## Next Steps

Great! Our ingress is up and running. See <https://kubernetes.io/docs/concepts/services-networking/ingress>
for more information on using Kubernetes Ingress Controllers.

If you want to take advantage of greater routing capabilities of Gloo, you should look at
[Gloo in gateway mode]({{% ref "http://localhost:1313/user_guides/ingress" %}}), which complements Gloo's Ingress
support, i.e., you can use both modes together in a single cluster. Gloo Gateway uses
[Kubernetes Custom Resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
instead of Ingress Objects as the only way to configure Ingress' beyond their basic routing spec is to use lots of
vendor-specific [Kubernetes Annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)
to your Kubernetes manifests.
