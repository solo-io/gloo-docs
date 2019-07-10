---
title: Concepts
weight: 4
description: Understanding Gloo
---

Gloo follows a declarative "intention" based configuration model. YAML (or convenience tools like a CLI or web interface) is used to specify intended state of the system and Gloo's control plane reifies these intentions. This approach simplifies an otherwise potentially complex configuration scenarios and plays nicely with automation, versioning, and the workflows built on "gitops". See below for more:

{{% children description="true" %}}
