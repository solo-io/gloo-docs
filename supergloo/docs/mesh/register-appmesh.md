---
title: "Registering AWS App Mesh"
weight: 30
description: "Installing App Mesh is slightly different from the other meshes. When we create a new App Mesh, we don't actually install one but -register- one with the AWS App Mesh managed control plane. In this section, we take a look at registering an instance of App Mesh and understanding the supporting SuperGloo API objects that get created when doing a mesh installation."
---

## Overview

AWS App Mesh uses an Envoy-based data plane to manage service-to-service communication within the mesh. App Mesh diverges slightly from the experience of other service-mesh implementations from the standpoint of its managed control plane. We cannot actually "install" anything for App Mesh as we are more interested in configuring the App Mesh control plane to "register" a new mesh for us and allow us to create App Mesh resources like `VirtualServices`, `VirtualNodes`, and `VirtualRouters` to drive the mesh behavior.

SuperGloo can be used to automate a lot of the steps needed to register a mesh, start sidecar auto-injection, and begin configuring traffic-management rules. Let's take a look at how to use SuperGloo to register an AWS App Mesh instance.


## Prep your environment

At the moment, SuperGloo uses Secrets with `ACCESS_KEY_ID` and `SECRET_ACCESS_KEY` to connect to AWS and perform the service-mesh registration. You can [get this keys from the AWS IAM service](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html). 

You can also get assistance in configuring your AWS access credentials with the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) by running the following:

```bash
aws configure
```

Follow the prompt to fill in the configuration profile for your credentials. 

Once you've located your keys (or configured your AWS CLI), you can run the following command to create the appropriate secret that SuperGloo will use to connect to the AWS APIs:

```bash
supergloo create secret aws --name aws --namespace supergloo-system \
--profile default --file ~/.aws/credentials 
```

If you want to pass the keys in directly:

```bash
supergloo create secret aws --name aws --namespace supergloo-system \
--access-key-id AKIAIOSFODNN7EXAMPLE --secret-access-key wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

{{% notice info %}}
We do not currently support using AWS Roles at this time. Please visit our slack or open a Github issue to let us know the priority and severity of this feature. 
{{% /notice %}}

Once you've configured your access secret, you can continue with the registration of the App Mesh service mesh.


## Registering App Mesh using SuperGloo

First, ensure that SuperGloo has been initialized in your kubernetes cluster via `supergloo init` or the
[Supergloo Helm Chart](https://github.com/solo-io/supergloo/tree/master/install/helm/supergloo). See the
[installationn instructions]({{% ref "/installation" %}}) for detailed instructions on installing SuperGloo.

Once SuperGloo has been installed, we'll create a Mesh CRD with configuration parameters which will then trigger SuperGloo to register the mesh installation.

This can be done in one of three ways:

#### Option 1: Using the `supergloo` CLI in interactive mode:

SuperGloo can walk you step-by-step through the registration of an AWS App Mesh instance. Run the following command to get into `interactive` mode:

```bash
supergloo register appmesh -i
```

This will walk you through a few prompts that can be used to configure your service mesh. Here's an example:

* `name for the mesh` - give the mesh a name; this will be used as the mesh name in AWS console
* `namespace for the mesh` - the location into which to install the SuperGloo `Mesh` CRD. Choose `supergloo-system` or the namespace of your choice.
* `choose a secret` - pick the one you just created in the prep step above
* `which aws region` - you'll want to pick the AWS region into which to create the App mesh that coincides with where you want to deploy your application infrastructure (where you're running EKS, ECS, Fargate, EC2, etc)
* `SuperGloo auto-inject sidecar proxies` - choose `yes` for a simplified user experience (let the auto-injection handle the init of the sidecars and registration of the `VirtualNodes`)
* `Namespace to be auto-injected` - can be more than one namespace, but pick the namespaces to include in the auto-injection
* `Auto-injection configuration` - pick `default` unless you want to customize the template used for auto injection
* `Pod label for virtual node assignment` - At the moment, `VirtualNode` auto-registration will be based on pod labels. For example, in a Kubernetes Deployment you may have a sepc.template with labels of `vn-name=reviews` -- in that case, add the name `vn-name` to this last question in the interactive prompt.

At this point, you can check the `supergloo-system` namespace to verify that the `sidecar-injector` pod has been started correctly:

```bash
kubectl get pod -n supergloo-system 

NAME                              READY   STATUS    RESTARTS   AGE
discovery-7b5c758ff9-gc52p        1/1     Running   0          7d
mesh-discovery-7689cc84fd-9f29q   1/1     Running   0          7d
sidecar-injector-867b67cf-8bd95   1/1     Running   0          5s
supergloo-6c4c7db574-zvkq4        1/1     Running   0          7d
```

We should also see the `Mesh` CRD has been created:

```bash
kubectl get mesh -n supergloo-system 

NAME           AGE
demo-appmesh   1m
```

Lastly, we should see our mesh created in AWS App Mesh:

```bash
aws appmesh list-meshes

{
    "meshes": [
        {
            "meshName": "demo-appmesh", 
            "arn": "arn:aws:appmesh:us-west-2:410461945957:mesh/demo-appmesh"
        }
    ]
}
```

You can also see this in the AWS web console (note: make sure you check the exact region where you installed the mesh):


![AWS App Mesh Console page](/img/aws-app-mesh-listing.png "AWS App Mesh Console")



#### Option 2: Using the `supergloo` CLI:

We can also use the `supergloo` CLI with appropriate parameter flags as show below. These are the same options that we saw in the previous interactive mode:

```bash
supergloo register appmesh --name demo-appmesh --namespace supergloo-system --secret supergloo-system.aws --region us-west-2 --auto-inject true --select-namespaces bookinfo-appmesh --virtual-node-label vn-name

```

See `supergloo register appmesh --help` for the full list of installation options for istio.

#### Option 3: Using `kubectl apply` on a yaml file:

Lastly, we can use a CRD/YAML file directly to create the `Mesh` resource. SuperGloo's `mesh-discovery` component will recognize this configuration and initiate the process to register with App Mesh.

```yaml
cat <<EOF | kubectl apply --filename -
apiVersion: supergloo.solo.io/v1
kind: Mesh                                   
metadata:                                                                    
  name: demo-appmesh
  namespace: supergloo-system                                           
spec:                                                                        
  awsAppMesh:                                                      
    awsSecret:                                                  
      name: aws                                                   
      namespace: supergloo-system                                       
    enableAutoInject: true                                          
    injectionSelector:                                              
      namespaceSelector:                                               
        namespaces:                                                     
        - bookinfo-appmesh                                           
    region: us-west-2                                                 
    virtualNodeLabel: vn-name   
EOF
```

Once you've created the `Mesh` CRD, you can track the progress of the App Mesh registration by watching the logs of the `mesh-discovery` component:

```bash
kubectl logs -n supergloo-system -f mesh-discovery-7689cc84fd-9f29q  
```

## Uninstalling AWS App Mesh


To uninstall the App Mesh registration run the following commands:

```bash
kubectl delete secret aws -n supergloo-system
kubectl delete mesh demo-appmesh -n supergloo-system
```


{{% notice info %}}
These commands will not currently delete the resources on the AWS side. It's important to make sure to run the following cleanup script to clean up the AWS App Mesh resources on the AWS side:
{{% /notice %}}

In the `src` for `SuperGloo` is a `hack` directory that will allow you to clean up ALL App Mesh resources (including `VirtualNode`, `VirtualRouter`, etc):

```bash
./supergloo/hack/eks/appmesh/cleanup.sh demo-appmesh
```


## Where to next?

Once you've got AWS App Mesh registered using SuperGloo, go to the traffic-routing guides to see how to use SuperGloo's unified traffic-management API to control the traffic in your service mesh without having to deal directly with all of the App Mesh specific objects. You should find a simplified experience for App Mesh with the SuperGloo APIs. 


{{% notice info %}}
More to come in the traffic-routing section for App Mesh. Stay tuned!
{{% /notice %}}