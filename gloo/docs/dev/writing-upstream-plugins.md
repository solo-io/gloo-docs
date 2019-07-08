---
title: "Service Discovery Plugins"
title: "Extending Service Discovery with Upstream Plugins"
weight: 5
---

## Intro

Gloo uses the [v1.Upstream]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/upstream.proto.sk.md">}}) config object to define routable destinations for Gloo. These are converted inside Gloo

This tutorial will show how we can add an *Upstream Plugin* to Gloo to extend Gloo with service discovery data.

Rather than provide a trivial example, we'll use VM instance groups on Google Compute Engine as our Upstream type, 
and the corresponding VM instances as its endpoints.

Note that *any* backend store of service addresses can be plugged into Gloo in this way. 

It will be the job of our plugin to connect to the external source of truth (in this case, the Google Compute Engine API) and convert it to configuration which Gloo can then supply to Envoy for routing. 

## Environment Setup

To set up a development environment for Gloo including installing prerequisites to generate code and build docker images, [see the dev setup guide]({{< ref "setting-up-dev-environment.md">}}). Make sure you 
include the **Enabling Code Generation** section of that tutorial.

## Upstream Plugin

For Gloo, an upstream represents a single service backed by one or more *endpoints* (where each endpoint is an IP or Hostname plus port) that accepts TCP or HTTP traffic. Upstreams can provide their endpoints to Gloo hard-coded inside their YAML spec, as with the `static` Upstream type. Alternatively, Upstreams can provide information to Gloo so that 
a corresponding Gloo plugin can perform Endpoint Discovery (EDS).  

This tutorial will cover an EDS-style plugin, where the user will provide a Google Compute Engine (GCE) Upstream to Gloo, and our plugin will retrieve each endpoint for that upstream.

Let's begin.

## Adding the new Upstream Type to Gloo's API

The first step we'll take will be to add a new [**UpstreamType**]({{< ref "/v1/github.com/solo-io/gloo/projects/gloo/api/v1/upstream.proto.sk.md#upstreamspec" >}}) to Gloo. 

All of Gloo's APIs are defined as protobuf files (`.proto`). The list of Upstream Types live in the [plugins.proto](https://github.com/solo-io/gloo/blob/master/projects/gloo/api/v1/plugins.proto) file, where Gloo's core API objects (Upstream, Virtual Service, Proxy, Gateway) are bound to plugin-specific configuration.

We'll write a simple `UpstreamSpec` proto for the new `gce` upstream type:

```proto
syntax = "proto3";
package gce.plugins.gloo.solo.io;

option go_package = "github.com/solo-io/gloo/projects/gloo/pkg/api/v1/plugins/gce";

import "gogoproto/gogo.proto";
option (gogoproto.equal_all) = true;

// Upstream Spec for Google Compute Engine Upstreams
// GCE Upstreams represent a set of one or more addressable VM instances for a VM Instance Group
message UpstreamSpec {
    // The name of the Instance Group
    string instance_group_name = 1;
    // region in which the instance group lives
    string instance_group_region = 2;
    // the GCP project to which the instance group belongs
    string projectId = 3;
}
```

Let's follow the established convention and place our proto code into a new `gce` directory in the `api/v1/plugins` API root:

```bash
# cd to the gloo directory
cd ${GOPATH}/src/github.com/solo-io/gloo
# make the new gce plugin directory
mkdir -p projects/gloo/api/v1/plugins/gce
# paste the proto code from above to projects/gloo/api/v1/plugins/gce/gce.proto 
cat > projects/gloo/api/v1/plugins/gce/gce.proto <<EOF
syntax = "proto3";
package gce.plugins.gloo.solo.io;

option go_package = "github.com/solo-io/gloo/projects/gloo/pkg/api/v1/plugins/gce";

import "gogoproto/gogo.proto";
option (gogoproto.equal_all) = true;

// Upstream Spec for Google Compute Engine Upstreams
// GCE Upstreams represent a set of one or more addressable VM instances for a VM Instance Group
message UpstreamSpec {
    // The name of the Instance Group
    string instance_group_name = 1;
    // region in which the instance group lives
    string instance_group_region = 2;
    // the GCP project to which the instance group belongs
    string projectId = 3;
}
EOF

```

You can view the complete `gce.proto` here: [gce.proto](../gce.proto). 


Now we need to add the new GCE `UpstreamSpec` to Gloo's list of Upstream Types. This can be found in 
the [`plugins.proto`](https://github.com/solo-io/gloo/blob/master/projects/gloo/api/v1/plugins.proto) file at the API root (projects/gloo/api/v1)/

First, we'll add an import to the top of the file

{{< highlight yaml "hl_lines=31-32" >}}
syntax = "proto3";
package gloo.solo.io;
option go_package = "github.com/solo-io/gloo/projects/gloo/pkg/api/v1";

import "google/protobuf/struct.proto";

import "gogoproto/gogo.proto";
option (gogoproto.equal_all) = true;

import "github.com/solo-io/gloo/projects/gloo/api/v1/ssl.proto";
import "github.com/solo-io/gloo/projects/gloo/api/v1/extensions.proto";
import "github.com/solo-io/gloo/projects/gloo/api/v1/circuit_breaker.proto";
import "github.com/solo-io/gloo/projects/gloo/api/v1/load_balancer.proto";
import "github.com/solo-io/gloo/projects/gloo/api/v1/connection.proto";

import "github.com/solo-io/gloo/projects/gloo/api/v1/plugins/aws/aws.proto";
import "github.com/solo-io/gloo/projects/gloo/api/v1/plugins/rest/rest.proto";
import "github.com/solo-io/gloo/projects/gloo/api/v1/plugins/grpc/grpc.proto";
import "github.com/solo-io/gloo/projects/gloo/api/v1/plugins/grpc_web/grpc_web.proto";
import "github.com/solo-io/gloo/projects/gloo/api/v1/plugins/hcm/hcm.proto";
import "github.com/solo-io/gloo/projects/gloo/api/v1/plugins/tcp/tcp.proto";
import "github.com/solo-io/gloo/projects/gloo/api/v1/plugins/azure/azure.proto";
import "github.com/solo-io/gloo/projects/gloo/api/v1/plugins/consul/consul.proto";
import "github.com/solo-io/gloo/projects/gloo/api/v1/plugins/kubernetes/kubernetes.proto";
import "github.com/solo-io/gloo/projects/gloo/api/v1/plugins/retries/retries.proto";
import "github.com/solo-io/gloo/projects/gloo/api/v1/plugins/static/static.proto";
import "github.com/solo-io/gloo/projects/gloo/api/v1/plugins/stats/stats.proto";
import "github.com/solo-io/gloo/projects/gloo/api/v1/plugins/transformation/prefix_rewrite.proto";
import "github.com/solo-io/gloo/projects/gloo/api/v1/plugins/transformation/transformation.proto";
import "github.com/solo-io/gloo/projects/gloo/api/v1/plugins/faultinjection/fault.proto";
// add the following line:
import "github.com/solo-io/gloo/projects/gloo/api/v1/plugins/gce/gce.proto";

{{< /highlight >}}

Next we'll add the new `UpstreamSpec` from our import. Locate the `UpstreamSpec` at the bottom of the `plugins.proto` file. The new `gce` UpstreamSpec must be added to the `upstream_type` oneof, like so:

{{< highlight yaml "hl_lines=27-28" >}}

// Each upstream in Gloo has a type. Supported types include `static`, `kubernetes`, `aws`, `consul`, and more.
// Each upstream type is handled by a corresponding Gloo plugin.
message UpstreamSpec {

    UpstreamSslConfig ssl_config = 6;

    // Circuit breakers for this upstream. if not set, the defaults ones from the Gloo settings will be used.
    // if those are not set, [envoy's defaults](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/cluster/circuit_breaker.proto#envoy-api-msg-cluster-circuitbreakers)
    // will be used.
    CircuitBreakerConfig circuit_breakers = 7;
    LoadBalancerConfig load_balancer_config = 8;
    ConnectionConfig connection_config = 9;

    // Use http2 when communicating with this upstream
    // this field is evaluated `true` for upstreams
    // with a grpc service spec
    bool use_http2 = 10;

    // Note to developers: new Upstream Plugins must be added to this oneof field
    // to be usable by Gloo.
    oneof upstream_type {
        kubernetes.plugins.gloo.solo.io.UpstreamSpec kube = 1;
        static.plugins.gloo.solo.io.UpstreamSpec static = 4;
        aws.plugins.gloo.solo.io.UpstreamSpec aws = 2;
        azure.plugins.gloo.solo.io.UpstreamSpec azure = 3;
        consul.plugins.gloo.solo.io.UpstreamSpec consul = 5;
        // add the following line
        gce.plugins.gloo.solo.io.UpstreamSpec gce = 11;
    }
}

{{< /highlight >}}

You can view the complete `plugins.proto` here: [plugins.proto](../plugins.proto). 

Great! We're all set to run code generation on Gloo and begin writing our plugin!

## Running the Code Generation

To regenerate code in the project, we will need `go`, `make`, `dep`, and `protoc` installed. If they aren't already, [see the dev setup guide]({{< ref "setting-up-dev-environment.md">}}).

To (re)generate code:

```bash
# go to gloo root dir
cd ${GOPATH}/src/github.com/solo-io/gloo
# run code generation 
make generated-code # add -B if you need to re-run 

```

We should be able to see modifications and additions to the generated code in `projects/gloo/pkg/api/v1`. Run `git status` to see what's been changed.

Let's start writing our plugin!

### Plugin code

#### Skeleton

We'll start by creating a new package/directory for our code to live in. Following the convention in Gloo, we'll create our new package at `projects/gloo/pkg/plugins/gce`:

```bash
cd ${GOPATH}/src/github.com/solo-io/gloo
mkdir -p projects/gloo/pkg/plugins/gce
touch projects/gloo/pkg/plugins/gce/plugin.go
```

We'll start writing the code for our plugin in `plugin.go`:

```go
package gce

type plugin struct{}

func NewPlugin() *plugin {
	return &plugin{}
}

```

So far, our plugin is just a plain go struct with no features. In order to provide service discovery for Gloo, our plugin needs to implement two interfaces: the [`plugins.UpstreamPlugin`](https://github.com/solo-io/gloo/blob/master//projects/gloo/pkg/plugins/plugin_interface.go#L43) and [`discovery.DiscoveryPlugin`](https://github.com/solo-io/gloo/blob/master/projects/gloo/pkg/discovery/discovery.go#L21) interfaces.

Let's add the functions necessary to implement these interfaces:

```go
package gce

import (
	"github.com/envoyproxy/go-control-plane/envoy/api/v2"
	"github.com/solo-io/gloo/projects/gloo/pkg/api/v1"
	"github.com/solo-io/gloo/projects/gloo/pkg/discovery"
	"github.com/solo-io/gloo/projects/gloo/pkg/plugins"
	"github.com/solo-io/solo-kit/pkg/api/v1/clients"
)

type plugin struct{}

func NewPlugin() *plugin {
	return &plugin{}
}

func (*plugin) ProcessUpstream(params plugins.Params, in *v1.Upstream, out *v2.Cluster) error {
	// we'll add our implementation here
}
func (*plugin) WatchEndpoints(writeNamespace string, upstreamsToTrack v1.UpstreamList, opts clients.WatchOpts) (<-chan v1.EndpointList, <-chan error, error) {
	// we'll add our implementation here
}

// it is sufficient to return nil here 
func (*plugin) Init(params plugins.InitParams) error {
	return nil
}

// though required by the plugin interface, this function is not necesasary for our plugin 
func (*plugin) DiscoverUpstreams(watchNamespaces []string, writeNamespace string, opts clients.WatchOpts, discOpts discovery.Opts) (chan v1.UpstreamList, chan error, error) {
	return nil, nil, nil
}

// though required by the plugin interface, this function is not necesasary for our plugin 
func (*plugin) UpdateUpstream(original, desired *v1.Upstream) (bool, error) {
	return false, nil
}

```

#### ProcessUpstream

Our plugin now implements the required interfaces and can be plugged into Gloo. For the purpose of this tutorial, 
we will only need the `ProcessUpstream` and `WatchEndpoints` functions to be implemented for our plugin. The rest
can be no-op and will simply be ignored by Gloo.

First, let's handle `ProcessUpstream`. `ProcessUpstream` is called for every **Upstream** known to Gloo in 
each iteration of Gloo's translation loop (in which Gloo config is translated to Envoy config). `ProcessUpstream`
looks at each individual Upstream (the user input object) and modifies, if necessary, the ouptut [Envoy Cluster](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api/v2/cds.proto) corresponding to that Upstream. 

Our `ProcessUpstream` function should:
* Check that the user's Upstream is *ours* (of type GCE)
* If so, mark the Cluster to use EDS

Let's implement that in our function right now:

```go
package gce

import (
	//...

	// add these imports to use Envoy's API
	envoyapi "github.com/envoyproxy/go-control-plane/envoy/api/v2"
	envoycore "github.com/envoyproxy/go-control-plane/envoy/api/v2/core"
)

//...

func (*plugin) ProcessUpstream(params plugins.Params, in *v1.Upstream, out *v2.Cluster) error {
	// check that the upstream is our type (GCE)
	if _, ok := in.UpstreamSpec.UpstreamType.(*v1.UpstreamSpec_Gce); !ok {
		// not gce, return early
		return nil
	}
	// tell Envoy to use EDS to get endpoints for this cluster 
	out.ClusterDiscoveryType = &envoyapi.Cluster_Type{
		Type: envoyapi.Cluster_EDS,
	}
	// tell envoy to use ADS to resolve Endpoints  
	out.EdsClusterConfig = &envoyapi.Cluster_EdsClusterConfig{
		EdsConfig: &envoycore.ConfigSource{
			ConfigSourceSpecifier: &envoycore.ConfigSource_Ads{
				Ads: &envoycore.AggregatedConfigSource{},
			},
		},
	}
	return nil
} 

```

All EDS-based plugins must implement the above function. See the `kubernetes` plugin for another example plugin for Envoy EDS. 

#### WatchEndpoints

The last piece our plugin needs is the `WatchEndpoints` function.  Here's where the meat of our plugin will live. 

We need to:

* Poll the GCE API
* Retrieve the list of instances and instance groups
* Correlate those addresses with the user's GCE Upstreams 
* Compose a list of Endpoints and send them on a channel to Gloo
* Repeat this at some interval to keep endpoints updated

So let's start writing our function. We'll need to add some imports to interact with the GCE API.

First, run the following command to download the Google Cloud SDK:

```bash
go get google.golang.org/api/compute/v1
```

Now we'll add the imports we need

```go
package gce

import (
	//...

	// add these imports to use Google Compute Engine's API
	"golang.org/x/oauth2/google"
	"google.golang.org/api/compute/v1"	
)
```

We can download these imports to our project with `dep ensure`:

```bash
cd ${GOPATH}/src/github.com/solo-io/gloo
dep ensure -v
```

Now we can develop our plugin.

Before we can discover our endpoints, we'll need to connect to the Google Compute API for Instances. Let's implement a function to initialize our client for us:

```go

// initialize client for talking to Google Compute Engine API
func initializeClient(ctx context.Context) (*compute.InstancesService, error) {
	// initialize google credentials from a custom environment variable
	// environment variables are not a secure way to share credentials to our application
	// and are only used here for the sake of convenience
	// we will store the content of our Google Developers Console client_credentials.json
	// as the value for GOOGLE_CREDENTIALS_JSON
	credsJson := []byte(os.Getenv("GOOGLE_CREDENTIALS_JSON"))
	creds, err := google.CredentialsFromJSON(ctx, credsJson, compute.ComputeScope)
	if err != nil {
		return nil, err
	}
	token := option.WithTokenSource(creds.TokenSource)
	svc, err := compute.NewService(ctx, token)
	if err != nil {
		return nil, err
	}
	instancesClient := compute.NewInstancesService(svc)

	return instancesClient, nil
}

```

For the purpose of the tutorial, we'll simply pass our Google API Credentials 
as the environment variable `GOOGLE_CREDENTIALS_JSON`. In a real 
production environment we'd want to retrieve
credentials from a secret store such as Kubernetes or Vault.

See https://cloud.google.com/video-intelligence/docs/common/auth on downloading this file. Its contents should be stored to an environment variable on the server running Gloo. We can set this on the deployment template for Gloo once we're ready to deploy to Kube.

Now that we have access to our client, we're ready to set up our polling 
function. It should retrieve the list of 
VMs from GCE and convert them to Endpoints 
for Gloo. Additionally, it should track 
the Upstream each Endpoint belongs to, and 
ignore any endpoints that don't belong to 
an upstream.

The declaration for our function reads as follows:

```go
// one call results in a list of endpoints for our upstreams
func getLatestEndpoints(instancesClient *compute.InstancesService, upstreams v1.UpstreamList) (v1.EndpointList, error) {
	//...
}
```

`getLatestEndpoints` will take as inputs the instances client and the for which we're upstreams discovering endpoints. Its outputs will be a list of endpoints and an error (if encountered during polling).

{{< highlight go "hl_lines=1-10" >}}

// one call results in a list of endpoints for our upstreams
func getLatestEndpoints(instancesClient *compute.InstancesService, upstreams v1.UpstreamList) (v1.EndpointList, error) {

	// initialize a new list of endpoints
	var result v1.EndpointList

	// for each upstream, retrieve its endpoints
	for _, us := range upstreams {
		gceSpec := us.UpstreamSpec.GetGce()
		if gceSpec == nil {
			// skip non-GCE upstreams
			continue
		}
	}
	
	return result, nil
}


{{< /highlight >}}
