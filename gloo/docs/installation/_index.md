---
title: Installing Gloo
weight: 2
---

Gloo can be installed in several different ways. The most common and customization way to deploy Gloo is to 
install on Kubernetes **[using the published helm chart](install_with_helm)**. For a faster introduction, 
follow the **[open source quick start guide](quick_start)**. And see below for notes on deploying with 
**[Google Kubernetes Engine](gke)** and **[Docker](docker-compose)

## Quick Start on Kubernetes

<table>
<tr>
<td  width="30%">
<img src="kube.png" />
</td>
<td>
To quickly get up and running with open source Gloo on Kubernetes, check out the <a href="quick_start"><b>quick start guide</b></a>. 
</td>
</tr>
</table>

## Production Deployment with Helm

<div class="table">
<table>
<tr>
<td width="30%"><img src="helm.png"/></td>
<td>
Gloo was designed for production deployment to Kubernetes. The Gloo control plane and proxies can be customized 
by <a href="install_with_helm"><b>deploying using the helm chart.</b></a> 
</td>
</tr>
</table>
</div>


## Deploying on Other Platforms

There are several other ways to deploy open source Gloo. 

<div class="table">
<table>
<tr>
<td width="50%"><img src="gke-logo.png" /></td>
<td width="50%"><img src="docker.png"/></td>
</tr>
<tr>
<td>
Gloo can run on multiple variants of Kubernetes. Check out this guide if you are <a href="gke"><b>installing on a Google Kubernetes Engine (GKE) cluster.</b></a> 
</td>
<td>
Gloo can be deployed locally for testing purposes using <b><a href="docker-compose">docker compose.</a></b>  
</td>
</tr>
</table>
</div>

