---
title: Rate Limiting
weight: 10
description: Define limits on the number of requests per unit of time.
---

## Why Rate Limit

When we expose services to potentially unknown, or "less-trusted users," we need mechanisms at the edge/ingress to control who's using the service and protect the system from malicious behavior whether intended or unintended. Rate Limiting is an approach to help limit how many times a user can call a given service, which helps protect upstream services. Additionally, rate-limiting may be necessary or desirable from a usage-quota perspective where we expose specific APIs through plans with pay-per-use policies.

Rate limiting can get complicated quickly, and to help with that Gloo provides two models. The [Gloo rate limiting](ratelimit) provides a simplified abstraction that handles the most common use cases easily. The [Envoy rate limiting](rate_limits_envoy) provides many more options to allow you to model your rate limits in a very fine grained approach. We suggest starting with the [Gloo rate limiting](ratelimit) approach first.

{{% children description="true" %}}
