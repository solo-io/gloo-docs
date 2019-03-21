---
title: Gloo and AWS App Mesh
weight: 85
description: Using Gloo as an ingress to App Mesh
---

AWS [App Mesh](https://docs.aws.amazon.com/app-mesh/latest/userguide/what-is-app-mesh.html) is an AWS-native service mesh implementation based on [Envoy Proxy](https://www.envoyproxy.io) and is currently in "public preview" for a handful of AWS regions. With App Mesh, AWS manages the service-mesh control plane and you connect up the data plane to the control plane by installing and configuring an Envoy Proxy instance next to your workloads. App Mesh can run in EC2, ECS, and EKS at the time of writing. 

Gloo complements service-mesh technology by bringing a powerful "API Gateway" to the edge (or even inside) of your mesh to handle things like:

* Oauth Flows
* Request/Response transformation
* API Aggregation with GraphQL
* Function routing

And more. Please see our [FAQ]({{< ref "/user_guides/faq/_index.md#what-s-the-difference-between-gloo-and-istio" >}}) for more on how Gloo can complement a service mesh.

## Getting started with AWS App Mesh

For this guide, we'll assume you want to use App Mesh on Kubernetes (AWS EKS in this case, but it can be any Kubernetes on AWS), but App Mesh is not limited to Kubernetes. 

We recommend you check out the [App Mesh examples](https://github.com/aws/aws-app-mesh-examples) repo for getting started with App Mesh and setting up the examples.

Once you have the examples installed, you should have an environment like this:

```noop
kubectl get pod

NAME                                 READY   STATUS    RESTARTS   AGE
colorgateway-57574547f7-mcnvq        2/2     Running   0          1h
colorteller-black-dd4665554-qtcdq    2/2     Running   0          1h
colorteller-blue-78f84c8d75-cx7zl    2/2     Running   0          1h
colorteller-red-6fd785755d-68n8n     2/2     Running   0          1h
colorteller-white-55c5ddc644-fqlg2   2/2     Running   0          1h
tcpecho-5b7cd4d994-2tlk2             1/1     Running   0          1h
tester-app-7c49d9f7db-d2qk8          1/1     Running   1          1h
```

Notice that we have Envoy Proxy running next to the workloads (except for the tcpecho and tester apps, that's fine). 

You should also verify you have all the Virtual Nodes, Virtual Routers, Routes, and Virtual Services:

```noop
aws appmesh describe-route --route-name colorteller-route \
   --virtual-router-name colorteller-vr --mesh-name ceposta-mesh

{
    "route": {
        "status": {
            "status": "ACTIVE"
        }, 
        "meshName": "ceposta-mesh", 
        "virtualRouterName": "colorteller-vr", 
        "routeName": "colorteller-route", 
        "spec": {
            "httpRoute": {
                "action": {
                    "weightedTargets": [
                        {
                            "virtualNode": "colorteller-blue-vn", 
                            "weight": 1
                        }
                    ]
                }, 
                "match": {
                    "prefix": "/"
                }
            }
        }, 
        "metadata": {
            "version": 5, 
            "lastUpdatedAt": 1553204779.5, 
            "createdAt": 1553201981.212, 
            "arn": "arn:aws:appmesh:us-west-2:410461945957:mesh/ceposta-mesh/virtualRouter/colorteller-vr/route/colorteller-route", 
            "uid": "98aaf4e4-d568-4f45-9925-3ea46696f61b"
        }
    }
}
```

## Using Gloo as the Ingress for App Mesh

In our above example, the `colorgateway` service calls the `colorteller` service which has a few variants (`colorteller-black`, `colorteller-red`, `colorteller-white`, etc). Both of those services are part of the mesh, and we can control the routing between the components with the mesh. To get traffic into the mesh with a powerful API Gateway like Gloo, all we have to do is the following:

1. Install Gloo
2. Create a Gloo VirtualService
3. Create a Route to where we want to bring traffic into the mesh

Installing Gloo is [covered adequately in other sections]({{< ref "/installation/_index.md" >}}) of the documentation.

To accomplish steps 2 and 3, run the following command:


```noop
glooctl add route --path-prefix /appmesh/color \
   --prefix-rewrite /color --dest-name default-colorgateway-9080    
```

Now let's figure out what the right URL is to contact Gloo:

```bash
glooctl proxy url

http://a034a61854c2111e992a70a2a7eb7b9a-398563398.us-west-2.elb.amazonaws.com:80
```
And then call our new API:

```bash
curl $(glooctl proxy url)/appmesh/color

{"color":"blue", "stats": {"blue":1}}
```

And there you have it! You now have a powerful L7 Ingress and API Gateway for managing traffic coming into your cluster being served with AWS App Mesh. 

### Limitations

Currently, AWS App Mesh is fairly simple in its capabilities. It does very limited routing, does not have a way to auto-inject proxies next to your workloads, cannot do mTLS, etc. As App Mesh adds more capabilities, we'll integrate deeper. Even with its current limitations, if you would like to connect multiple meshes together (multiple App Mesh or other heterogeneous implementations like Istio), please check out the [SuperGloo](https://supergloo.solo.io) project where we make it easy to stitch together multiple meshes.