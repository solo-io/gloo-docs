---
title: AWS Lambda Routing
weight: 1
description: AWS Upstream configuration guide.
---

## How to setup and use an AWS Upstream

There are 2 steps to enabling Gloo to discover and access AWS Lambda services.

1. Create an AWS Secret to give Gloo credentials to access AWS.
2. Create a Gloo upstream referencing the AWS Secret that will populate the Gloo function catalog with available
AWS Lambda functions. 

### Create an AWS Secret

This command can be used to create a Kubernetes secret which contains the AWS Access Key and Secret Key needed by Gloo
to connect to AWS in order to do Lambda function discovery.

```noop
glooctl create secret aws --help

Create an AWS secret with the given name

Usage:
  glooctl create secret aws [flags]

Flags:
      --access-key string   aws access key
  -h, --help                help for aws
      --name string         name of the resource to read or write
  -n, --namespace string    namespace for reading or writing resources (default "gloo-system")
      --secret-key string   aws secret key

Global Flags:
  -i, --interactive     use interactive mode
  -o, --output string   output format: (yaml, json, table)
```

For example, the following command creates an AWS secret named `my-aws` in the (default) namespace `gloo-system`.
You can name the secret (`--name 'your_name'`) whatever you like. Just make sure you use the correct name when
referencing it from AWS Upstream.

```shell 
glooctl create secret aws \
    --name 'my-aws' \
    --namespace gloo-system \
    --access-key '<AWS ACCESS KEY>' \
    --secret-key '<AWS SECRET KEY>'
```

You can see the details of the created secret using `kubectl`.

```shell
kubectl describe secret my-aws -n gloo-system
```

```noop
Name:         my-aws
Namespace:    gloo-system
Labels:       <none>
Annotations:  resource_kind: *v1.Secret

Type:  Opaque

Data
====
aws:  84 bytes
```

### Create an AWS Upstream

This command can be used to create an AWS upstream. Once it is created, Gloo can perform Lambda function discovery, and you can create virtual services with route rules referencing Lambda functions.

```noop
glooctl create upstream aws --help

AWS Upstreams represent a set of AWS Lambda Functions for a Region that can be routed to with Gloo. AWS Upstreams require a valid set of AWS Credentials to be provided. These should be uploaded to Gloo using `glooctl create secret aws`

Usage:
  glooctl create upstream aws [flags]

Flags:
      --aws-region string                                       region for AWS services this upstream utilize (default "us-east-1")
      --aws-secret-name glooctl create secret aws --help        name of a secret containing AWS credentials created with glooctl. See glooctl create secret aws --help for help creating secrets
      --aws-secret-namespace glooctl create secret aws --help   namespace where the AWS secret lives. See glooctl create secret aws --help for help creating secrets (default "gloo-system")
  -h, --help                                                    help for aws
      --name string                                             name of the resource to read or write
  -n, --namespace string                                        namespace for reading or writing resources (default "gloo-system")

Global Flags:
  -i, --interactive     use interactive mode
  -o, --output string   output format: (yaml, json, table)
```

For example, this command creates an AWS Upstream named `my-aws-upstream` in the (default) namespace `gloo-system`. This upstream will contain the Lambda functions available in the `us-east-1` region under the AWS account referenced by the `my-aws` secret, which lives in the `gloo-system` namespace. 

```shell
glooctl create upstream aws \
    --name 'my-aws-upstream' \
    --namespace 'gloo-system' \
    --aws-region 'us-east-1' \
    --aws-secret-name 'my-aws' \
    --aws-secret-namespace 'gloo-system'
```

### Usage

To create a route rule for your new AWS upstream, you can use the `glooctl add route` command. For example, this command creates a route rule that matches the path `/helloworld` and routes to the `helloworld` Lambda function in the AWS Upstream `my-aws-upstream`.

```shell
glooctl add route \
    --name 'default' \
    --namespace 'gloo-system' \
    --path-prefix '/helloworld' \
    --dest-name 'my-aws-upstream' \
    --aws-function-name 'helloworld'
```

## More Details

For more details, please look at these other sources

* [Gloo Upstreams Concept]({{< ref "/introduction/concepts#upstreams" >}})
* [Create Secret AWS Command Line]({{< ref "/cli/glooctl_create_secret_aws" >}})
* [Create Upstream AWS Command Line]({{< ref "/cli/glooctl_create_upstream_aws" >}})
* [AWS Access Keys](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys) 
