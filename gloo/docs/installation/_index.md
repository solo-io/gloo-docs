---

title: Installing Gloo
weight: 2
---

# Gloo Open-Source

Gloo Open-Source runs in 3 different modes to enable different use cases:


<dic markdown=1>
<table>
  <tr height="100">
    <td width="10%">
      <a href="gateway"><img src="../img/Gloo-01.png" width="60"/></a>
    </td>
    <td>
     Run Gloo in `gateway` mode to function as an API Gateway. This mode uses Kubernetes Custom Resources to configure routing. This is the most fully-featured and customizable installation of Gloo, and is our <b>recommended install for first-time users</b>.
    </td>
  </tr>
  <tr height="100">
    <td width="10%">
      <a href="knative"><img src="../img/knative.png" width="60"/></a>
    </td>
    <td>
     Run Gloo in `knative` mode to act an ingress controller for Knative (configured using the `ClusterIngress` CRD), providing routing to Knative services without the need to install Istio.
    </td>
  </tr>
  <tr height="100">
    <td width="10%">
      <a href="ingress"><img src="../img/ingress.png" width="60"/></a>
    </td>
    <td>Run Gloo in `ingress` mode to act as a standard Kubernetes Ingress controller. In this mode, Gloo will import 
        its configuration from the `extensions/v1beta1.Ingress` Kubernetes resource. This can be used to achieve compatibility with the standard Kubernetes ingress API. Note that Gloo's Ingress API does not support customization via annotations. If you wish to extend Gloo beyond the functions of basic ingress, it is recommended to run Gloo in `gateway` mode.
    </td>
  </tr>
</table>
</div>

> Note: The installation modes are not mutually exclusive, e.g. if you wish to run `gateway` in conjunction with `ingress`, it can be done by installing both options to the same (or different) namespaces.

# Gloo Enterprise

Gloo Enterprise has a single installation workflow:


<dic markdown=1>
<table>
  <tr height="100">
    <td width="10%">
      <a href="enterprise"><img src="../img/gloo-ee.png" width="60"/></a>
    </td>
    <td>
    Gloo Enterprise is based on the open-source Gloo Gateway with additional (closed source) UI and plugins. See [the Gloo Enterprise documentation](../enterprise) for more details on the additional features of the Enterprise version of Gloo.
    </td>
  </tr>
</table>
</div>
